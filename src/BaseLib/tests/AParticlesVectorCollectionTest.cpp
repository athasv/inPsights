//
// Created by Michael Heuer on 29.10.17.
//

#include <gtest/gtest.h>
#include <ParticlesVectorCollection.h>
#include <sstream>

using namespace testing;
using namespace Eigen;

class AParticlesVectorCollectionTest : public Test {
public:

    Eigen::Vector3d pos1{1,2,3};
    Eigen::Vector3d pos2{4,5,6};
    ElectronsVector electronsVector;
    ElectronsVectorCollection electronsVectorCollection;
    AtomsVector atomsVector;
    AtomsVectorCollection atomsVectorCollection;

    void SetUp() override {
        Particle<Spins::SpinType > e1 = {pos1,Spins::SpinType::alpha};
        Particle<Spins::SpinType > e2 = {pos2,Spins::SpinType::beta};
        electronsVector.append(e1);
        electronsVector.append(e2);

        electronsVectorCollection.append(electronsVector);
        electronsVectorCollection.append(electronsVector);

        Particle<Elements::ElementType> a1 = {pos1,Elements::ElementType::H};
        Particle<Elements::ElementType> a2 = {pos2,Elements::ElementType::Og};
        atomsVector.append(a1);
        atomsVector.append(a2);
        atomsVectorCollection.append(atomsVector);
        atomsVectorCollection.append(atomsVector);
    };
};

TEST_F(AParticlesVectorCollectionTest, Constructor) {
    EXPECT_TRUE(false);
}

TEST_F(AParticlesVectorCollectionTest, CopyConstructor) {
    EXPECT_TRUE(false);
}

TEST_F(AParticlesVectorCollectionTest, SpinTypeParticlesVectorCollection) {
    std::stringstream stringstream;
    stringstream << electronsVectorCollection;

    std::string expectedOutput = "Vector 1:\n"
                                 " 1 ea   1.00000   2.00000   3.00000\n"
                                 " 2 eb   4.00000   5.00000   6.00000\n"
                                 "\n"
                                 "Vector 2:\n"
                                 " 1 ea   1.00000   2.00000   3.00000\n"
                                 " 2 eb   4.00000   5.00000   6.00000\n"
                                 "\n";
    ASSERT_EQ(stringstream.str(), expectedOutput);
}

TEST_F(AParticlesVectorCollectionTest, ElementTypeParticlesVectorCollection) {
    std::stringstream stringstream;
    stringstream << atomsVectorCollection;

    std::string expectedOutput = "Vector 1:\n"
                                 " 1 H    1.00000   2.00000   3.00000\n"
                                 " 2 Og   4.00000   5.00000   6.00000\n"
                                 "\n"
                                 "Vector 2:\n"
                                 " 1 H    1.00000   2.00000   3.00000\n"
                                 " 2 Og   4.00000   5.00000   6.00000\n"
                                 "\n";
    ASSERT_EQ(stringstream.str(), expectedOutput);
}

TEST_F(AParticlesVectorCollectionTest, Distance) {
    EXPECT_TRUE(false);
}
