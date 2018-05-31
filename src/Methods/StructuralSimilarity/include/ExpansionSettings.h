//
// Created by Michael Heuer on 03.05.18.
//

#ifndef AMOLQCPP_EXPANSIONSETTINGS_H
#define AMOLQCPP_EXPANSIONSETTINGS_H

#include <cassert>
#include "ElementType.h"

namespace ExpansionSettings{
    namespace Radial{
        enum class BasisType{
            equispaced = 0, adaptive,
        };

        const double radiusZero = 1e-10;

        extern unsigned nmax;
        extern BasisType basisType;
        extern double sigmaAtom;

        extern unsigned integrationSteps;
        extern double desiredAbsoluteError,desiredRelativeError;

        void defaults();
        void checkBounds(unsigned n);
    };

    namespace Angular {
        extern unsigned lmax;

        void defaults();
        void checkBounds(unsigned l, int m = 0);

    };

    namespace Cutoff {
        extern double cutoffRadius, cutoffWidth, centerWeight;

        void defaults();
        double innerPlateauRadius();
    }

    namespace Alchemical{
        extern std::map<std::pair<Elements::ElementType,Elements::ElementType>,double> pairSimilarities;
    }//TODO implement and use

    enum class Mode {
        Generic = 0, TypeSpecific
    };

    extern Mode mode;
    extern double zeta;  // LocalSimilarity exponent
    extern double gamma; // StructuralSimilarity regularization

    void defaults();
    void checkBounds(unsigned n, unsigned l, int m);
};


#endif //AMOLQCPP_EXPANSIONSETTINGS_H
