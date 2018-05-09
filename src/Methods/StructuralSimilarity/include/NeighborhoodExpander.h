//
// Created by Michael Heuer on 20.04.18.
//

#ifndef AMOLQCPP_NEIGHBORHOODEXPANDER_H
#define AMOLQCPP_NEIGHBORHOODEXPANDER_H

#include "RadialGaussianBasis.h"
#include "AngularBasis.h"
#include "Environment.h"

#include "Cutoff.h"
#include <BoostSphericalHarmonics.h>
#include <Particle.h>

class NeighborhoodExpander{
public:
    explicit NeighborhoodExpander(const AtomsVector & atoms,
                                  const ExpansionSettings& settings = ExpansionSettings::defaults())
            : atoms_(atoms),
              s_(settings),
              radialGaussianBasis_(s_),
              angularBasis_(s_.angular),

              coefficientsVector_(unsigned(atoms_.numberOfEntities()), settings),
              cutoffFunction_()
    {}

    Environment expandParticle(const Atom &center,
                               const Atom &neighbor,
                               double neighborSigma) const {
        double theta,phi;

        Eigen::Vector3d centerToNeighborVector = (neighbor.position()-center.position());
        double centerToNeighborDistance = centerToNeighborVector.norm();

        if(centerToNeighborDistance > 0.) {
            BoostSphericalHarmonics::ToSphericalCoords(centerToNeighborVector.normalized(), theta, phi);
            if (phi < 0.) phi += 2 * M_PI;
        } else { // center and neighbor positions are identical
            theta = 0.;
            phi = 0.;
        }

        Environment singleNeighbor(1,s_);

        for (unsigned n = 1; n <= s_.radial.nmax; ++n) {
            for (unsigned l = 0; l <= s_.angular.lmax; ++l) {
                for (int m = -int(l); m <= int(l); ++m) {
                    auto coefficient = radialGaussianBasis_.computeCoefficient(n, l, centerToNeighborDistance, neighborSigma)
                                       * angularBasis_.computeCoefficient(l, m, theta, phi);

                    singleNeighbor.storeCoefficient(0, n, l, m, coefficient);
                }
            }
        }
        return singleNeighbor;
    }

    const ExpansionSettings& getSettings(){
        return s_;
    }

    void compute(){
        for (unsigned i = 0; i < atoms_.numberOfEntities(); ++i) {
            expandParticlesInNeighborhood(i);
        }
    }

    void expandParticlesInNeighborhood(unsigned centerParticleId){
        assert(centerParticleId >= 0
               && "The center particle ID must be greater or equal to zero.");
        assert(centerParticleId < atoms_.numberOfEntities()
               && "The center particle ID must be smaller than the total number of particles.");


        // USE ATOMKIT HERE
        for (unsigned j = 0; j < atoms_.numberOfEntities(); ++j) {

            /*//TODO arbitrary? change this */ double neighborSigma = s_.radial.sigmaAtom;

            double centerToNeighborDistance = Cutoff::distance(atoms_[j].position(),
                                                               atoms_[centerParticleId].position());

            // skip this iteration if particle i is outside the cutoff radius
            if (!cutoffFunction_.withinCutoffRadiusQ(centerToNeighborDistance)){
                continue;
            } else {
                double weight = 1;
                double weightScale = cutoffFunction_.getWeight(centerToNeighborDistance);

                if (j == centerParticleId) weight *= cutoffFunction_.getCenterWeight();

                auto atomicCoefficientsVector = expandParticle(atoms_[centerParticleId],
                                                               atoms_[j], neighborSigma);
                atomicCoefficientsVector *= weight*weightScale;

                coefficientsVector_.storeSingleNeighborExpansion(j, atomicCoefficientsVector);
            }
        }
    }

private:
    AtomsVector atoms_;
    ExpansionSettings s_;
    RadialGaussianBasis radialGaussianBasis_;
    AngularBasis angularBasis_;

    Environment coefficientsVector_;
    Cutoff cutoffFunction_;
};

#endif //AMOLQCPP_NEIGHBORHOODEXPANDER_H
