//
// Created by Michael Heuer on 02.10.18.
//

#ifndef INPSIGHTS_MAXIMAPROCESSOR_H
#define INPSIGHTS_MAXIMAPROCESSOR_H

#include "Reference.h"
#include "SimilarReferences.h"
#include "Sample.h"
#include <Motifs.h>
#include <Statistics.h>
#include <VoxelCube.h>

class MaximaProcessor {
public:

    MaximaProcessor(YAML::Emitter& yamlDocument, const std::vector<Sample> &samples, AtomsVector atoms);

    unsigned long addReference(const Reference &reference);

    void doMotifBasedEnergyPartitioning(const Reference &reference);

    void calculateStatistics(const std::vector<std::vector<SimilarReferences>> &clusteredGloballySimilarMaxima);

    // selects nWanted structures and prints the statistic data
    void printCluster(std::vector<ElectronsVector> &structures, std::vector<VoxelCube> voxelCubes);

    YAML::Node getYamlNode();

    std::string getYamlDocumentString();

private:
    YAML::Emitter& yamlDocument_;
    const std::vector<Sample> &samples_;
    AtomsVector atoms_;
    Motifs motifs_;
    SingleValueStatistics valueStats_, EtotalStats_;
    VectorStatistics TeStats_, EeStats_, EnStats_, intraMotifEnergyStats_;
    TriangularMatrixStatistics SeeStats_, VeeStats_, VnnStats_, interMotifEnergyStats_, ReeStats_;
    MatrixStatistics VenStats_, RenStats_;

    Eigen::MatrixXd Vnn_;
};

#endif //INPSIGHTS_MAXIMAPROCESSOR_H
