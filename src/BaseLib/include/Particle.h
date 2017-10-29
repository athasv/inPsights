//
// Created by Michael Heuer on 29.10.17.
//

#ifndef AMOLQCGUI_PARTICLE_H
#define AMOLQCGUI_PARTICLE_H

#include <Eigen/Core>

class Particle {
public:
    explicit Particle(const Eigen::Vector3d& position);

    Eigen::Vector3d position() const;
    void position(const Eigen::Vector3d& position);

protected:
    Eigen::Vector3d position_;
};
#endif //AMOLQCGUI_PARTICLE_H
