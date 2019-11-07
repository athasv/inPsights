/* Copyright (C) 2018-2019 Michael Heuer.
 *
 * This file is part of inPsights.
 * inPsights is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * inPsights is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with inPsights. If not, see <https://www.gnu.org/licenses/>.
 */

#include "NeighborhoodExpander.h"
#include "Cutoff.h"
#include "AngularBasis.h"
#include "ParticleKit.h"
#include <SOAPSettings.h>

using namespace SOAP;

NeighborhoodExpander::NeighborhoodExpander()
        : radialGaussianBasis_(){}
        
NeighborhoodExpansion NeighborhoodExpander::expandEnvironment(const Environment& e, int expansionTypeId) const {
    NeighborhoodExpansion neighborhoodExpansion;

    auto nmax = Radial::settings.nmax();
    auto lmax = Angular::settings.lmax();
    auto sigmaAtom  = Radial::settings.sigmaAtom();
    auto radiusZero = Radial::settings.radiusZero();
    auto centerWeight = Cutoff::settings.centerWeight();

    for (const auto& neighborCoordsPair : e.selectParticles(expansionTypeId)) {

        const auto& neighborCoords = neighborCoordsPair.second;

        double weight = 1; //TODO TypeSpecific Value?
        double weightScale = Cutoff::getWeight(neighborCoords.r);

        if (neighborCoords.r <= radiusZero)
            weight *= centerWeight;

        for (unsigned n = 1; n <= nmax; ++n) {
            for (unsigned l = 0; l <= lmax; ++l) {

                //radialGaussianBasis_.
                auto radialCoeff = radialGaussianBasis_.computeCoefficients(neighborCoords.r, sigmaAtom);
                for (int m = -int(l); m <= int(l); ++m) {

                    //TODO use TypeSpecific sigma value? Is neighbor sigma right?
                    auto coeff = radialCoeff(n-1,l)* AngularBasis::computeCoefficient(l, m, neighborCoords.theta, neighborCoords.phi)
                                 * weight*weightScale;
                    neighborhoodExpansion.storeCoefficient(n,l,m,coeff);
                }
            }
        }
    }
    return neighborhoodExpansion;
}

TypeSpecificNeighborhoodsAtOneCenter
NeighborhoodExpander::computeParticularExpansions(const Environment &e) {
    TypeSpecificNeighborhoodsAtOneCenter expansions;

    auto mode = General::settings.mode();
    switch (mode) {
        case General::Mode::typeAgnostic: {
            auto noneTypeId = 0;
            expansions.emplace(noneTypeId, expandEnvironment(e, noneTypeId));
            break;
        }
        case General::Mode::chemical: {
            for(auto & [type, count] : ParticleKit::kit){
                expansions.emplace(type, expandEnvironment(e, type));
            }
            break;
        }
        case General::Mode::alchemical: {
            for(auto & [type, count] : ParticleKit::kit){
                expansions.emplace(type, expandEnvironment(e, type));
            }
            break;
        }
        case General::Mode::undefined:
            throw std::exception();
    }
    return expansions;
}

MolecularCenters
NeighborhoodExpander::computeMolecularExpansions(MolecularGeometry molecule) {
    assert(ParticleKit::isSubsetQ(molecule)
           && "The molecule must be composable from the set of particles specified in the particle kit");

    MolecularCenters expansions;

    for (unsigned k = 0; k < unsigned(molecule.numberOfEntities()); ++k) {
        auto currentEnumeratedType = molecule.findEnumeratedTypeByIndex(k);
        expansions[currentEnumeratedType] = computeParticularExpansions(Environment(molecule, currentEnumeratedType));
    }

    return expansions;
}
