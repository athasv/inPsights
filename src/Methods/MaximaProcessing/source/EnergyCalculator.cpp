//
// Created by heuer on 12.12.18.
//
#include <EnergyCalculator.h>
#include <ClusterData.h>
#include <MolecularGeometry.h>
#include <SpinCorrelation.h>
#include <CoulombPotential.h>
#include <EnergyPartitioning.h>
#include <VoxelCubeGeneration.h>
#include <EnergyPartitioning.h>
#include <spdlog/spdlog.h>

EnergyCalculator::EnergyCalculator(YAML::Emitter& yamlDocument, const std::vector<Sample>& samples, AtomsVector atoms)
        :
        yamlDocument_(yamlDocument),
        samples_(samples),
        atoms_(atoms),
        Vnn_(CoulombPotential::energies<Element>(atoms_))
{
    VnnStats_.add(Vnn_);
    EnStats_.add(EnergyPartitioning::ParticleBased::oneAtomEnergies(Vnn_));
}

unsigned long EnergyCalculator::addReference(const Reference &reference) {
    auto count = unsigned(reference.count());

    Eigen::VectorXd value(1); value[0] = reference.value();
    Eigen::MatrixXd spinCorrelations_ = SpinCorrelation::spinCorrelations(reference.maximum().typesVector()).cast<double>();
    // Maximum related statistics
    valueStats_.add(value, count);
    SeeStats_.add(spinCorrelations_,count);

    // Sample related statistics
    for (auto & id : reference.sampleIds()) {
        Eigen::VectorXd Te = samples_[id].kineticEnergies_;
        Eigen::MatrixXd Vee = CoulombPotential::energies(samples_[id].sample_);
        Eigen::MatrixXd Ven = CoulombPotential::energies(samples_[id].sample_,atoms_);
        Eigen::VectorXd Ee = EnergyPartitioning::ParticleBased::oneElectronEnergies(Te, Vee, Ven, Vnn_);
        TeStats_.add(Te,1);
        VeeStats_.add(Vee,1);
        VenStats_.add(Ven,1);
        EeStats_.add(Ee,1);
    }
    return count;
}

void EnergyCalculator::doMotifBasedEnergyPartitioning(const Reference &reference) {
    // Sample related statistics
    for (auto & id : reference.sampleIds()) {
        Eigen::VectorXd Te = samples_[id].kineticEnergies_;
        Eigen::MatrixXd Vee = CoulombPotential::energies(samples_[id].sample_);
        Eigen::MatrixXd Ven = CoulombPotential::energies(samples_[id].sample_,atoms_);

        auto motifEnergies = EnergyPartitioning::MotifBased::calculateInterationEnergies(motifs_, Te, Vee, Ven, Vnn_);

        intraMotifEnergyStats_.add(motifEnergies.first,1);
        interMotifEnergyStats_.add(motifEnergies.second,1);
    }
}

void EnergyCalculator::calculateStatistics(const std::vector<std::vector<SimilarReferences>>& clusteredGloballySimilarMaxima){
    using namespace YAML;

    yamlDocument_ << Key << "En" << Comment("[Eh]") << Value << EnStats_
                  << Key << "Clusters" << BeginSeq;

    size_t totalCount = 0;
    for (auto& cluster : clusteredGloballySimilarMaxima) {
        valueStats_.reset();
        SeeStats_.reset();
        TeStats_.reset();
        EeStats_.reset();
        VeeStats_.reset();
        VenStats_.reset();
        intraMotifEnergyStats_.reset();
        interMotifEnergyStats_.reset();

        std::vector<ElectronsVector> structures;
        for (auto &simRefVector : cluster) {

            // Iterate over references being similar to the representative reference.
            for (const auto &ref : simRefVector.similarReferencesIterators()){
                totalCount += addReference(*ref);
            }
            structures.push_back(simRefVector.representativeReference().maximum());
        }

        // Motif analysis (requires spin correlation data)
        auto adjacencyMatrix = GraphAnalysis::filter(SeeStats_.mean().cwiseAbs(), 1.00);
        motifs_ = Motifs(adjacencyMatrix, MolecularGeometry(atoms_, cluster[0].representativeReference().maximum()));
        for (auto &simRefVector : cluster) {
            for (const auto &ref : simRefVector.similarReferencesIterators()){
                doMotifBasedEnergyPartitioning(*ref);
            }
        }


        std::vector<VoxelCube> voxelCubes;
        if(VoxelCubeGeneration::settings.generateVoxelCubesQ())
            voxelCubes = VoxelCubeGeneration::fromCluster(cluster, samples_);

        yamlDocument_ <<  ClusterData(TeStats_.getTotalWeight(), structures, valueStats_, TeStats_, EeStats_,
                                      SeeStats_, VeeStats_, VenStats_,
                                      motifs_, intraMotifEnergyStats_, interMotifEnergyStats_, voxelCubes);
    }
    spdlog::info("overall count {}", totalCount);
    assert(totalCount == samples_.size() && "The total count must match the sample size.");

    yamlDocument_ << EndSeq;
    assert(yamlDocument_.good());
}

YAML::Node EnergyCalculator::getYamlNode(){
    return YAML::Load(yamlDocument_.c_str());
}

std::string EnergyCalculator::getYamlDocumentString(){
    return std::string(yamlDocument_.c_str());
}
