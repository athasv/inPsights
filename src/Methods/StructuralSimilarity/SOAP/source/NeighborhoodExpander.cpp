//
// Created by Michael Heuer on 15.05.18.
//

#include "NeighborhoodExpander.h"
#include "CutoffFunction.h"
#include "AngularBasis.h"
#include "ParticleKit.h"
#include <ExpansionSettings.h>

NeighborhoodExpander::NeighborhoodExpander()
        : radialGaussianBasis_(){}
        
NeighborhoodExpansion NeighborhoodExpander::expandEnvironment(const Environment& e, int expansionTypeId) const {
    NeighborhoodExpansion neighborhoodExpansion;

    auto nmax = Radial::settings.nmax.get();
    auto lmax = Angular::settings.lmax.get();
    auto sigmaAtom  = Radial::settings.sigmaAtom.get();
    auto radiusZero = Radial::settings.radiusZero.get();
    auto centerWeight = Cutoff::settings.centerWeight.get();

    for (const auto& neighborCoordsPair : e.selectParticles(expansionTypeId)) {

        const auto& neighborCoords = neighborCoordsPair.second;

        double weight = 1; //TODO TypeSpecific Value? //const auto& neighbor = neighborCoordsPair.first;
        double weightScale = CutoffFunction::getWeight(neighborCoords.r);

        if (neighborCoords.r <= radiusZero)
            weight *= centerWeight; //TODO return something here?

        for (unsigned n = 1; n <= nmax; ++n) {
            for (unsigned l = 0; l <= lmax; ++l) {

                //radialGaussianBasis_.
                auto radialCoeff = radialGaussianBasis_.computeCoefficients(neighborCoords.r, sigmaAtom);
                for (int m = -int(l); m <= int(l); ++m) {

                    //TODO use TypeSpecific sigma value? Is neighbor sigma right?
                    //auto coeff = coefficient(n, l, m, neighborCoords, weight, weightScale);//,neighborSigma);
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
NeighborhoodExpander::computeParticularExpansions(const Environment &e) { // WORKS!
    TypeSpecificNeighborhoodsAtOneCenter expansions;

    switch (Settings::mode) {
        case Settings::Mode::typeAgnostic: {
            auto noneTypeId = 0;
            expansions.emplace(noneTypeId, expandEnvironment(e, noneTypeId));
            break;
        }
        case Settings::Mode::chemical: {
            for(auto & type : ParticleKit::kit){
                expansions.emplace(type.first, expandEnvironment(e, type.first));
            }
            break;
        }
        case Settings::Mode::alchemical: {
            for(auto & type : ParticleKit::kit){
                expansions.emplace(type.first, expandEnvironment(e, type.first));
            }
            break;
        }
    }
    return expansions;
}

MolecularCenters
NeighborhoodExpander::computeMolecularExpansions(MolecularGeometry molecule) {
    assert(ParticleKit::isSubsetQ(molecule)
           && "The molecule must be composable from the set of particles specified in the particle kit");
    MolecularCenters exp;

    auto radiusZero = Radial::settings.radiusZero.get();

    //TODO CHECK HERE FOR IDENTICAL CENTERS!
    for (unsigned k = 0; k < unsigned(molecule.numberOfEntities()); ++k) {

        // check if center was calculated already ;
        // TODO: not possible, if type specific center value is chosen which currently isn't the case;
        bool computedAlreadyQ = false;

        NumberedType<int> existingNumberedType;
        for (unsigned i = 0; i < k; ++i) {
            if((molecule[i].position()-molecule[k].position()).norm() <= radiusZero){
                existingNumberedType = molecule.findNumberedTypeByIndex(i);
                computedAlreadyQ = true;
                //std::cout << "found " << existingNumberedType << std::endl;
                break;
            }
        }
        auto newNumberedType = molecule.findNumberedTypeByIndex(k);
        if(computedAlreadyQ){
            exp[newNumberedType] = exp[existingNumberedType];
        } else {
            exp[newNumberedType] = computeParticularExpansions(Environment(molecule, molecule[k].position()));
        }
    }

    return exp;
}
