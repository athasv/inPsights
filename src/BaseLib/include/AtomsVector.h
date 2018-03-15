//
// Created by heuer on 24.05.17.
//

#ifndef AMOLQCPP_ATOMCOLLECTION_H
#define AMOLQCPP_ATOMCOLLECTION_H

#include "ParticlesVector.h"
#include "ElementTypesVector.h"
#include "Atom.h"

class AtomsVector : public ParticlesVector{
public:
    AtomsVector() = default;
    explicit AtomsVector(const Eigen::VectorXd& positions);
    AtomsVector(const Eigen::VectorXd& positions, const Eigen::VectorXi& elementTypes);
    AtomsVector(const PositionsVector &positionsVector,
                   const ElementTypesVector &elementTypesVector);

    Atom operator[](long i) const;

    void insert (const Atom& atom, long i);
    void append (const Atom& atom);
    void prepend(const Atom& atom);
    void permute(long i, long j);


    const ElementTypesVector& elementTypesVector() const;
    ElementTypesVector& elementTypesVector();

    friend std::ostream& operator<<(std::ostream& os, const AtomsVector& ac);

private:
    ElementTypesVector elementTypesVector_;
};

#endif //AMOLQCPP_ATOMCOLLECTION_H
