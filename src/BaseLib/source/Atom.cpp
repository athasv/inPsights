//
// Created by heuer on 24.05.17.
//

#include "Atom.h"

using namespace Eigen;
using namespace Elements;

Atom::Atom(const Vector3d& position, const ElementType& elementType)
        : Particle(position),
          elementType_(elementType) {};

Atom::Atom(double x, double y, double z, const ElementType& elementType)
        : Particle(x, y, z),
          elementType_(elementType) {};

Atom::Atom(const Particle &particle, const ElementType& elementType)
        : Particle(particle),
          elementType_(elementType) {}

Elements::ElementType Atom::elementType() const {
    return elementType_;
};
