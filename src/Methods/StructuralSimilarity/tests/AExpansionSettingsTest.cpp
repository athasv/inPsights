//
// Created by Michael Heuer on 15.05.18.
//

#include <gtest/gtest.h>
#include "ExpansionSettings.h"

using namespace testing;

class AExpansionSettingsTest : public ::testing::Test {
public:
};

TEST_F(AExpansionSettingsTest , uninitialized) {
    ASSERT_EQ(ExpansionSettings::Radial::nmax,5);
    ASSERT_EQ(ExpansionSettings::Radial::basisType, ExpansionSettings::Radial::BasisType::equispaced);
    ASSERT_EQ(ExpansionSettings::Radial::sigmaAtom,0.5);

    ASSERT_EQ(ExpansionSettings::Radial::integrationSteps,100);
    ASSERT_EQ(ExpansionSettings::Radial::desiredAbsoluteError,0.0);
    ASSERT_EQ(ExpansionSettings::Radial::desiredRelativeError,1e-6);


    ASSERT_EQ(ExpansionSettings::Angular::lmax,3);

    ASSERT_EQ(ExpansionSettings::Cutoff::cutoffRadius,4.0);
    ASSERT_EQ(ExpansionSettings::Cutoff::cutoffWidth,1.0);
    ASSERT_EQ(ExpansionSettings::Cutoff::centerWeight,1.0);


    ExpansionSettings::Radial::nmax = 4;
    ExpansionSettings::Angular::lmax = 4;

    ASSERT_EQ(ExpansionSettings::Radial::nmax,4);
    ASSERT_EQ(ExpansionSettings::Angular::lmax,4);
}

TEST_F(AExpansionSettingsTest, defaults) {
    ExpansionSettings::defaults();

    ASSERT_EQ(ExpansionSettings::Radial::nmax,5);
    ASSERT_EQ(ExpansionSettings::Radial::basisType,ExpansionSettings::Radial::BasisType::equispaced);
    ASSERT_EQ(ExpansionSettings::Radial::sigmaAtom,0.5);

    ASSERT_EQ(ExpansionSettings::Angular::lmax,3);

    ASSERT_EQ(ExpansionSettings::Cutoff::cutoffRadius,4.0);

    ExpansionSettings::Radial::nmax = 4;
    ExpansionSettings::Angular::lmax = 4;

    ASSERT_EQ(ExpansionSettings::Radial::nmax,4);
    ASSERT_EQ(ExpansionSettings::Angular::lmax,4);
}
