//
// Created by Michael Heuer on 2019-01-08.
//

#ifndef INPSIGHTS_VOXELCUBEGENERATION_H
#define INPSIGHTS_VOXELCUBEGENERATION_H

#include <VoxelCube.h>

class Sample;
class SimilarReferences;

#include <ISettings.h>
#include <Property.h>
namespace Settings {
    class VoxelCubeGeneration : public ISettings {
        inline static const std::string className = {VARNAME(VoxelCubeGeneration)};
    public:
        Property<bool> generateVoxelCubesQ = {false, VARNAME(generateVoxelCubesQ)};
        Property<bool> centerCubesAtElectronsQ = {true, VARNAME(centerCubesAtElectronsQ)};
        Property<uint16_t> dimension = {16, VARNAME(dimension)};
        Property<VoxelCube::VertexComponentsType > length = {2, VARNAME(length)};


        VoxelCubeGeneration() = default;
        explicit VoxelCubeGeneration(const YAML::Node &node);
        void appendToNode(YAML::Node &node) const override;
    };
}
YAML_SETTINGS_DECLARATION(Settings::VoxelCubeGeneration)


namespace VoxelCubeGeneration{
    inline Settings::VoxelCubeGeneration settings {};

    std::vector<VoxelCube> fromCluster(
            const std::vector<SimilarReferences> &cluster,
            const std::vector<Sample> &samples);
};

#endif //INPSIGHTS_VOXELCUBEGENERATION_H
