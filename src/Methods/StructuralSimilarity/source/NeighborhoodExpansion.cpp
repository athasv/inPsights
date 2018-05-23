//
// Created by Michael Heuer on 15.05.18.
//

#include "NeighborhoodExpansion.h"
#include "ExpansionSettings.h"

NeighborhoodExpansion::NeighborhoodExpansion()
        : angularEntityLength_(angularEntityLength(ExpansionSettings::Angular::lmax)), //lmax*lmax+ 2*lmax+1
          entityLength_(ExpansionSettings::Radial::nmax * angularEntityLength_),//TODO rename
          coefficients_(Eigen::VectorXcd::Zero(entityLength_))
{}

std::complex<double> NeighborhoodExpansion::getCoefficient(unsigned n, unsigned l, int m) const {
    ExpansionSettings::checkBounds(n,l,m);
    return coefficients_[(n-1)*angularEntityLength_ + (angularEntityLength(l-1)) + (m+l)];
}

unsigned NeighborhoodExpansion::angularEntityLength(int l) const {
    if( l < 0) return 0;
    else return l*l + angularSubEntityLength(unsigned(l));
}

unsigned  NeighborhoodExpansion::angularSubEntityLength(unsigned l) const {
    return 2*l+1;
}

void NeighborhoodExpansion::storeCoefficient(unsigned n, unsigned l, int m, const std::complex<double> &coefficient) {
    ExpansionSettings::checkBounds(n,l,m);
    assert(coefficient == coefficient && "Value cannot be NaN!");
    coefficients_[(n-1)*angularEntityLength_ + (angularEntityLength(l-1)) + (m+l)] += coefficient;
}

Eigen::VectorXcd NeighborhoodExpansion::asEigenVector() const {
    return coefficients_;
}

void NeighborhoodExpansion::operator*=(double weight){
    coefficients_ *= weight;
}

std::ostream& operator<<(std::ostream& os, const NeighborhoodExpansion & ne){
    for (unsigned n = 1; n <= ExpansionSettings::Radial::nmax; ++n) {
        os << " n: "<< n << std::endl;
        for (unsigned l = 0; l <= ExpansionSettings::Angular::lmax; ++l) {
            os << "  l: "<< l << std::endl;
            for (int m = -int(l); m <= int(l); ++m) {
                os << "   m: " << m << " " << ne.getCoefficient(n,l,m) << std::endl;
            }
        }
    }
    return os;
}
