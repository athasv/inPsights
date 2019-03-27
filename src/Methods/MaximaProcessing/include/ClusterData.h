//
// Created by Michael Heuer on 22.11.18.
//

#ifndef INPSIGHTS_CLUSTERDATA_H
#define INPSIGHTS_CLUSTERDATA_H

#include <Statistics.h>
#include <ParticlesVector.h>
#include <VoxelCube.h>
#include <Motifs.h>
#include <EnergyStatistics.h>

class ClusterData {
public:
    ClusterData() = default;

    ClusterData(unsigned totalNumberOfStructures,
                const std::vector<ElectronsVector> & exemplaricStructures,
                const SingleValueStatistics & valueStats,
                const VectorStatistics & TeStats,
                const VectorStatistics & EeStats,
                const TriangularMatrixStatistics & SeeStats,
                const TriangularMatrixStatistics & VeeStats,
                const MatrixStatistics & VenStats,
                const Motifs& motifs,
                const SingleValueStatistics & EtotalStats,
                const VectorStatistics & intraMotifEnergyStats,
                const TriangularMatrixStatistics & interMotifEnergyStats,
                const std::vector<VoxelCube>& voxelCubes
                );

    ElectronsVector representativeStructure() const;

    unsigned N_;
    std::vector<ElectronsVector> exemplaricStructures_;
    Motifs motifs_;
    SingleValueStatistics valueStats_, EtotalStats_;
    VectorStatistics EeStats_, intraMotifEnergyStats_; //TODO remove EeStats
    EnergyStatistics::ElectronicEnergy electronicEnergyStats_;
    TriangularMatrixStatistics SeeStats_;
    TriangularMatrixStatistics interMotifEnergyStats_;
    std::vector<VoxelCube> voxelCubes_;
};

namespace YAML {
    class Node; class Emitter;
    template <typename Type> struct convert;

    template<> struct convert<ClusterData> {
        static Node encode(const ClusterData &rhs);
        static bool decode(const Node &node, ClusterData &rhs);
    };
    Emitter &operator<<(Emitter &out, const ClusterData &p) ;
}

#endif //INPSIGHTS_CLUSTERDATA_H
