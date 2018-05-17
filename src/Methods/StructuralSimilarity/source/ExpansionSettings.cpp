//
// Created by Michael Heuer on 04.05.18.
//

#include "ExpansionSettings.h"
#include <cassert>

namespace ExpansionSettings {

    ExpansionMode mode = ExpansionMode::Generic;

    void checkBounds(unsigned n, unsigned l, int m) {
        Radial::checkBounds(n);
        Angular::checkBounds(l, m);
    }

    void defaults() {
        Radial::defaults();
        Angular::defaults();
        Cutoff::defaults();
        mode = ExpansionMode::Generic;
    };

    namespace Radial {

        unsigned nmax = 0;
        RadialGaussianBasisType basisType = RadialGaussianBasisType::equispaced;
        double sigmaAtom = 0;

        void defaults() {
            nmax = 5;
            basisType = RadialGaussianBasisType::equispaced;
            sigmaAtom = 0.5;
        };

        void checkBounds(unsigned n) {
            assert(n <= nmax && "n must be smaller than nmax");
            assert(n >= 1 && "n must greater than or equal to 1");
        }

    }

    namespace Angular {
        unsigned lmax = 0;

        void defaults() {
            lmax = 3;
        };


        void checkBounds(unsigned l, int m) {
            assert(l <= lmax && "l must be less than or equal to lmax");
            assert(unsigned(abs(m)) <= lmax && "abs(m) must be smaller than lmax");
        }
    }
    
    namespace Cutoff {
        double cutoffRadius = 0;
        double cutoffWidth = 0;
        double centerWeight = 0;

        void defaults() {
            cutoffRadius = 4.0;
            cutoffWidth = 1.0;
            centerWeight = 1.0;
        }

        double innerPlateauRadius() {
            return cutoffRadius - cutoffWidth;
        }

    }

}
