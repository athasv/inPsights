//
// Created by Michael Heuer on 03.05.18.
//

#include "Cutoff.h"
#include <cmath>
#include "ExpansionSettings.h"

bool Cutoff::withinCutoffRadiusQ(double distance) {
    return distance < ExpansionSettings::Cutoff::cutoffRadius;
}


double Cutoff::getWeight(double distanceFromExpansionCenter) {
    const auto innerPlateauRadius = ExpansionSettings::Cutoff::cutoffRadius - ExpansionSettings::Cutoff::cutoffWidth;
    const auto & cutoffWidth = ExpansionSettings::Cutoff::cutoffWidth;
    const auto & cutoffRadius = ExpansionSettings::Cutoff::cutoffRadius;

    //TODO delete centerWeight and use: 'if (0 <= distanceFromExpansionCenter...' instead?
    if (0 < distanceFromExpansionCenter && distanceFromExpansionCenter <= innerPlateauRadius)
        return 1.;
    else if (innerPlateauRadius < distanceFromExpansionCenter && distanceFromExpansionCenter <= cutoffRadius)
        return 0.5*( 1 + cos( M_PI*(distanceFromExpansionCenter-innerPlateauRadius)/cutoffWidth) );
    else
        return 0.;
};


double Cutoff::getWeight(const Eigen::Vector3d& position,
                         const Eigen::Vector3d& expansionCenter) {
    return getWeight(distance(position, expansionCenter));
}

Eigen::Vector3d Cutoff::getWeightGradient(const Eigen::Vector3d&position ) {
    const auto innerPlateauRadius = ExpansionSettings::Cutoff::cutoffRadius - ExpansionSettings::Cutoff::cutoffWidth;
    const auto & cutoffWidth = ExpansionSettings::Cutoff::cutoffWidth;
    const auto & centerWeight = ExpansionSettings::Cutoff::centerWeight;
    const auto & cutoffRadius = ExpansionSettings::Cutoff::cutoffRadius;

    double distanceFromExpansionCenter =position .norm();
    Eigen::Vector3d direction =position .normalized();

    if (distanceFromExpansionCenter <= innerPlateauRadius || distanceFromExpansionCenter > cutoffRadius)
        return Eigen::Vector3d::Zero();
    else if (innerPlateauRadius < distanceFromExpansionCenter && distanceFromExpansionCenter <= cutoffRadius)
        return 0.5*( 1 + sin( M_PI*(distanceFromExpansionCenter-innerPlateauRadius)/cutoffWidth)*M_PI/cutoffWidth )*direction;
};

double Cutoff::distance(const Eigen::Vector3d &position,
                        const Eigen::Vector3d &expansionCenter){
    return (position-expansionCenter).eval().norm();
}
