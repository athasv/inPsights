//
// Created by Leonard Reuter on 14.03.18.
//

#ifndef INPSIGHTS_VISUALIZATION_H
#define INPSIGHTS_VISUALIZATION_H


#include <Qt3DCore>
#include <Qt3DRender>
#include <Qt3DExtras>
#include <QtWidgets/QApplication>
#include <ParticlesVectorCollection.h>

namespace Visualization {
    int visualizeOptPath(int &argc, char **argv,
                         const AtomsVector &atoms,
                         const ElectronsVectorCollection &optimizationPath,
                         long nwanted = 300);

    ElectronsVectorCollection shortenPath(const ElectronsVectorCollection &optimizationPath,
                                          long nwanted);

    void drawEigenVector(Qt3DCore::QEntity *root,
                         const Eigen::MatrixXd &eigenvectors,
                         const Eigen::VectorXd &origin, int eigenvectorIndex);
}

#endif //INPSIGHTS_VISUALIZATION_H
