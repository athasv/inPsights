//
// Created by Michael Heuer on 30.05.18.
//

#ifndef INPSIGHTS_TESTMOLECULES_H
#define INPSIGHTS_TESTMOLECULES_H

#include <MolecularGeometry.h>
#include "NaturalConstants.h"


namespace TestMolecules {

    template <typename Type>
    Eigen::Vector3d inbetween(const ParticlesVector<Type>& pv,
            std::pair<Eigen::Index, Eigen::Index> indices, double shift = 0.5){
        assert(indices.first >= 0 && indices.first < pv.numberOfEntities());
        assert(indices.second >= 0 && indices.second < pv.numberOfEntities());
        return shift * (pv.positionsVector()[indices.second]
                       - pv.positionsVector()[indices.first]) + pv.positionsVector()[indices.first];
    }

    namespace twoElectrons {
        const MolecularGeometry oppositeSpin = {
                AtomsVector(),
                ElectronsVector({{Spin::alpha, {0, 0, 0.37}},
                                 {Spin::beta,  {0, 0,-0.37}}})};

        const MolecularGeometry oppositeSpinReversedOrder = {
                AtomsVector(),
                ElectronsVector({{Spin::beta,  {0, 0, 0.37}},
                                 {Spin::alpha, {0, 0,-0.37}}})};

        const MolecularGeometry sameSpinAlpha= {
                AtomsVector(),
                ElectronsVector({{Spin::alpha, {0, 0, 0.37}},
                                 {Spin::alpha, {0, 0,-0.37}}})};
        const MolecularGeometry sameSpinBeta = {
                AtomsVector(),
                ElectronsVector({{Spin::beta, {0, 0, 0.37}},
                                 {Spin::beta, {0, 0,-0.37}}})};
    }
    namespace threeElectrons {
        const MolecularGeometry normal = {
                AtomsVector(),
                ElectronsVector({{Spin::alpha, {0, 0, 0.37}},
                                 {Spin::alpha, {0, 0, 0.0}},
                                 {Spin::beta,  {0, 0,-0.37}}})};
        const MolecularGeometry spinFlipped = {
                AtomsVector(),
                ElectronsVector({{Spin::beta,  {0, 0, 0.37}},
                                 {Spin::beta,  {0, 0, 0.0}},
                                 {Spin::alpha, {0, 0,-0.37}}})};
        const MolecularGeometry ionic = {
                AtomsVector(),
                ElectronsVector({{Spin::alpha, {0, 0, 0.37}},
                                 {Spin::alpha, {0, 0,-0.37}},
                                 {Spin::beta,  {0, 0,-0.37}}})};
    }

    namespace eightElectrons {
        const MolecularGeometry square = {
                AtomsVector(),
                ElectronsVector({{Spin::alpha, { 1, 0, 0}},
                                 {Spin::alpha, { 1, 1, 0}},
                                 {Spin::alpha, { 0, 1, 0}},
                                 {Spin::alpha, {-1, 1, 0}},
                                 {Spin::beta,  {-1, 0, 0}},
                                 {Spin::beta,  {-1,-1, 0}},
                                 {Spin::beta,  { 0,-1, 0}},
                                 {Spin::beta,  { 1,-1, 0}}})};


        const MolecularGeometry cube = {
                AtomsVector(),
                ElectronsVector({{Spin::alpha, { 1, 1, 1}},
                                 {Spin::beta,  { 1, 1,-1}},
                                 {Spin::alpha, {-1,-1, 1}},
                                 {Spin::beta,  {-1,-1,-1}},
                                 {Spin::alpha, { 1,-1,-1}},
                                 {Spin::beta,  { 1,-1, 1}},
                                 {Spin::alpha, {-1, 1,-1}},
                                 {Spin::beta,  {-1, 1, 1}}
                                })};
    }
    namespace sixteenElectrons {
        const MolecularGeometry twoNestedCubes = {
                AtomsVector(),
                ElectronsVector({{Spin::alpha,{ 1, 1, 1}},
                                 {Spin::beta, { 1, 1,-1}},
                                 {Spin::alpha,{-1,-1, 1}},
                                 {Spin::beta, {-1,-1,-1}},
                                 {Spin::alpha,{ 1,-1,-1}},
                                 {Spin::beta, { 1,-1, 1}},
                                 {Spin::alpha,{-1, 1,-1}},
                                 {Spin::beta, {-1, 1, 1}},

                                 {Spin::beta, { 2, 2, 2}},
                                 {Spin::alpha,{ 2, 2,-2}},
                                 {Spin::beta, {-2,-2, 2}},
                                 {Spin::alpha,{-2,-2,-2}},
                                 {Spin::beta, { 2,-2,-2}},
                                 {Spin::alpha,{ 2,-2, 2}},
                                 {Spin::beta, {-2, 2,-2}},
                                 {Spin::alpha,{-2, 2, 2}}
                })};
    }


    namespace H2 {
        const MolecularGeometry nuclei = {
                AtomsVector({{Element::H, {0, 0, 0.37}},
                             {Element::H, {0, 0, -0.37}}}),{}};
        namespace ElectronsInCores {
            const MolecularGeometry normal = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::alpha, {0, 0, 0.37}},
                                     {Spin::beta,  {0, 0,-0.37}}})};

            const MolecularGeometry ionicLeft = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::alpha, {0, 0,-0.37}},
                                     {Spin::beta,  {0, 0,-0.37}}})};

            const MolecularGeometry ionicRight = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::alpha, {0, 0, 0.37}},
                                     {Spin::beta,  {0, 0, 0.37}}})};

            const MolecularGeometry translated = {
                    AtomsVector({{Element::H, {0+1, 0+1, 0.37+1}},
                                 {Element::H, {0+1, 0+1, -0.37+1}}}),
                    ElectronsVector({{Spin::alpha, {0+1, 0+1, 0.37+1}},
                                     {Spin::beta,  {0+1, 0+1,-0.37+1}}})};

            const MolecularGeometry reversedElectronOrder = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::beta,  {0, 0, 0.37}},
                                     {Spin::alpha, {0, 0,-0.37}}})};

            const MolecularGeometry flippedSpins = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::alpha, {0, 0, -0.37}},
                                     {Spin::beta,  {0, 0, 0.37}}})};
        }

        namespace ElectronsOutsideCores{
            const MolecularGeometry normal = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::alpha, {0, 0, 0.2}},
                                     {Spin::beta,  {0, 0,-0.2}}})};

            const MolecularGeometry offCenter = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::alpha, {0, 0.1, 0.2}},
                                     {Spin::beta,  {0,-0.1,-0.2}}})};

            const MolecularGeometry offCenterRotated90 = {
                    nuclei.atoms(),
                    ElectronsVector({{Spin::alpha, { 0.1, 0, 0.2}},
                                     {Spin::beta,  {-0.1, 0,-0.2}}})};
        }
    }

    namespace HeH {
        namespace ElectronsInCores {
            const MolecularGeometry normal = {
                    AtomsVector({{Element::He,{0, 0, 0.37}},
                                 {Element::H, {0, 0,-0.37}}}),
                    ElectronsVector({{Spin::alpha,{0, 0, 0.37}},
                                     {Spin::alpha,{0, 0, 0.37}},
                                     {Spin::beta, {0, 0,-0.37}}})};
        }
    }

    namespace BH3 {
        const double a = 1.15;
        const MolecularGeometry nuclei = {
                AtomsVector({{Element::B,{ 0, 0, 0}},
                             {Element::H,{ 0, 2.*a, 0}},
                             {Element::H,{-std::sqrt(3)*a,-1.*a, 0}},
                             {Element::H,{ std::sqrt(3)*a,-1.*a, 0}},
                            }),
                {}
        };

        const MolecularGeometry ionicMinimal = {
                nuclei.atoms(),
                ElectronsVector({{Spin::alpha, nuclei.atoms().positionsVector()[2]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[3]},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,2},0.25)},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,3},0.25)},
                                })};
        const MolecularGeometry ionicMinimalRotated = {
                nuclei.atoms(),
                ElectronsVector({{Spin::alpha, nuclei.atoms().positionsVector()[1]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[2]},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,1},0.25)},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,2},0.25)},
                                })};
        const MolecularGeometry ionicMinimalRotatedPermuted = {
                nuclei.atoms(),
                ElectronsVector({{Spin::alpha, nuclei.atoms().positionsVector()[1]},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,1},0.25)},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[2]},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,2},0.25)},
                                })};


        const MolecularGeometry ionic = {
                nuclei.atoms(),
                ElectronsVector({{Spin::alpha, nuclei.atoms().positionsVector()[0]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[1]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[2]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[3]},

                                 {Spin::beta , nuclei.atoms().positionsVector()[0]},
                                 {Spin::beta , nuclei.atoms().positionsVector()[1]},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,2},0.25)},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,3},0.25)}
                                })};

        const MolecularGeometry ionicMirrored = {
                nuclei.atoms(),
                ElectronsVector({{Spin::alpha, nuclei.atoms().positionsVector()[0]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[3]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[1]},
                                 {Spin::alpha, nuclei.atoms().positionsVector()[2]},

                                 {Spin::beta , nuclei.atoms().positionsVector()[0]},
                                 {Spin::beta , nuclei.atoms().positionsVector()[3]},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,1},0.25)},
                                 {Spin::beta , inbetween(nuclei.atoms(),{0,2},0.25)}
                                })};
    }

    namespace CO2{
        const MolecularGeometry nuclei = {
                AtomsVector({{Element::C,{0,0, 0}},
                             {Element::O,{0,0, 1}},
                             {Element::O,{0,0,-1}}}),{}};

        const MolecularGeometry nucleiPermuted = {
                AtomsVector({{Element::O,{0,0,-1}},
                             {Element::C,{0,0, 0}},
                             {Element::O,{0,0, 1}}}),{}};

        const MolecularGeometry isolatedNuclei = {
                AtomsVector({{Element::C,{0,0, 0}},
                             {Element::O,{0,0, 10}},
                             {Element::O,{0,0,-10}}}),{}};
    }

    namespace Ethane {
        /* 2      7  6   y x
         *  \      \/    |/
         *   0--*--1     *--z
         *  /\      \
         * 3  4      5
         */

        namespace {
            const double a = 0.7623 * 1.89;
            const double b = 1.1544 * 1.89;
            const double c = 0.5053 * 1.89;
            const double d = 0.8752 * 1.89;
        };

        const MolecularGeometry nuclei = {
                AtomsVector({{Element::C,{ 0,   0,-a}},
                             {Element::C,{ 0,   0, a}},
                             {Element::H,{ 0, 2*c,-b}},
                             {Element::H,{-d,  -c,-b}},
                             {Element::H,{ d,  -c,-b}},
                             {Element::H,{ 0,-2*c, b}},
                             {Element::H,{ d,   c, b}},
                             {Element::H,{-d,   c, b}}}
                             ),{}};

        const MolecularGeometry doublyIonic = {
                nuclei.atoms(),
                ElectronsVector({// C Cores
                                 {Spin::alpha/* 0*/,nuclei.atoms().positionsVector()[0]},
                                 {Spin::beta /* 1*/,nuclei.atoms().positionsVector()[0]},
                                 {Spin::alpha/* 2*/,nuclei.atoms().positionsVector()[1]},
                                 {Spin::beta /* 3*/,nuclei.atoms().positionsVector()[1]},
                                 // H Cores
                                 {Spin::alpha/* 4*/,nuclei.atoms().positionsVector()[2]},
                                 {Spin::alpha/* 5*/,nuclei.atoms().positionsVector()[3]},
                                 {Spin::alpha/* 6*/,nuclei.atoms().positionsVector()[4]},
                                 {Spin::alpha/* 7*/,nuclei.atoms().positionsVector()[5]},
                                 {Spin::beta /* 8*/,nuclei.atoms().positionsVector()[2]},
                                 {Spin::beta /* 9*/,nuclei.atoms().positionsVector()[5]},
                                 {Spin::beta /*10*/,nuclei.atoms().positionsVector()[6]},
                                 {Spin::beta /*11*/,nuclei.atoms().positionsVector()[7]},
                                 // C-C Bond
                                 {Spin::alpha/*12*/,inbetween(nuclei.atoms(),{0,1},0.25)},
                                 {Spin::beta /*13*/,inbetween(nuclei.atoms(),{1,0},0.25)},
                                 // C-H Bonds
                                 {Spin::beta /*14*/,inbetween(nuclei.atoms(),{0,3},0.25)},
                                 {Spin::beta /*15*/,inbetween(nuclei.atoms(),{0,4},0.25)},
                                 {Spin::alpha/*16*/,inbetween(nuclei.atoms(),{1,6},0.25)},
                                 {Spin::alpha/*17*/,inbetween(nuclei.atoms(),{1,7},0.25)}
                                 })};

        const MolecularGeometry doublyIonicDoublyRotated = {
                nuclei.atoms(),
                ElectronsVector({// C Cores
                                 {Spin::alpha/* 0*/,nuclei.atoms().positionsVector()[0]},
                                 {Spin::beta /* 1*/,nuclei.atoms().positionsVector()[0]},
                                 {Spin::alpha/* 2*/,nuclei.atoms().positionsVector()[1]},
                                 {Spin::beta /* 3*/,nuclei.atoms().positionsVector()[1]},
                                 // H Cores
                                 {Spin::alpha/* 4*/,nuclei.atoms().positionsVector()[3]},
                                 {Spin::alpha/* 5*/,nuclei.atoms().positionsVector()[4]},
                                 {Spin::alpha/* 6*/,nuclei.atoms().positionsVector()[2]},
                                 {Spin::alpha/* 7*/,nuclei.atoms().positionsVector()[6]},

                                 {Spin::beta /* 8*/,nuclei.atoms().positionsVector()[3]},
                                 {Spin::beta /* 9*/,nuclei.atoms().positionsVector()[6]},
                                 {Spin::beta /*10*/,nuclei.atoms().positionsVector()[7]},
                                 {Spin::beta /*11*/,nuclei.atoms().positionsVector()[5]},
                                 // C-C Bond
                                 {Spin::alpha/*12*/,inbetween(nuclei.atoms(),{0,1},0.25)},
                                 {Spin::beta /*13*/,inbetween(nuclei.atoms(),{1,0},0.25)},
                                 // C-H Bonds
                                 {Spin::beta /*14*/,inbetween(nuclei.atoms(),{0,4},0.25)},
                                 {Spin::beta /*15*/,inbetween(nuclei.atoms(),{0,2},0.25)},
                                 {Spin::alpha/*16*/,inbetween(nuclei.atoms(),{1,7},0.25)},
                                 {Spin::alpha/*17*/,inbetween(nuclei.atoms(),{1,5},0.25)}
                                })};
        const MolecularGeometry doublyIonicDoublyRotatedPermuted = { // swap els at core 2 with those at 4 and 5 with 7
                nuclei.atoms(),
                ElectronsVector({// C Cores
                                 {Spin::alpha/* 0*/,nuclei.atoms().positionsVector()[0]},
                                 {Spin::beta /* 1*/,nuclei.atoms().positionsVector()[0]},
                                 {Spin::alpha/* 2*/,nuclei.atoms().positionsVector()[1]},
                                 {Spin::beta /* 3*/,nuclei.atoms().positionsVector()[1]},
                                 // H Cores
                                 {Spin::alpha/* 4*/,nuclei.atoms().positionsVector()[3]},
                                 {Spin::alpha/* 5*/,nuclei.atoms().positionsVector()[2]},//*
                                 {Spin::alpha/* 6*/,nuclei.atoms().positionsVector()[4]},//*
                                 {Spin::alpha/* 7*/,nuclei.atoms().positionsVector()[6]},
                                 {Spin::beta /* 8*/,nuclei.atoms().positionsVector()[3]},
                                 {Spin::beta /* 9*/,nuclei.atoms().positionsVector()[6]},
                                 {Spin::beta /*10*/,nuclei.atoms().positionsVector()[5]},
                                 {Spin::beta /*11*/,nuclei.atoms().positionsVector()[7]},
                                 // C-C Bond
                                 {Spin::alpha/*12*/,inbetween(nuclei.atoms(),{0,1},0.25)},
                                 {Spin::beta /*13*/,inbetween(nuclei.atoms(),{1,0},0.25)},
                                 // C-H Bonds
                                 {Spin::beta /*14*/,inbetween(nuclei.atoms(),{0,2},0.25)},//*
                                 {Spin::beta /*15*/,inbetween(nuclei.atoms(),{0,4},0.25)},//*
                                 {Spin::alpha/*16*/,inbetween(nuclei.atoms(),{1,5},0.25)},
                                 {Spin::alpha/*17*/,inbetween(nuclei.atoms(),{1,7},0.25)}
                                })};

        const MolecularGeometry doublyIonicA = {
                nuclei.atoms(),
                ElectronsVector({//TODO correct molecule geom?
                                        {Spin::alpha/*0*/,inbetween(nuclei.atoms(),{0,1},0.25)},
                                        {Spin::alpha/*1*/,inbetween(nuclei.atoms(),{1,6},0.25)},
                                        {Spin::alpha/*2*/,inbetween(nuclei.atoms(),{1,7},0.25)},
                                        {Spin::beta /*3*/,inbetween(nuclei.atoms(),{1,0},0.25)},
                                        {Spin::beta /*4*/,inbetween(nuclei.atoms(),{0,3},0.25)},
                                        {Spin::beta /*5*/,inbetween(nuclei.atoms(),{0,4},0.25)}

                                })};

        const MolecularGeometry doublyIonicB = {
                nuclei.atoms(),
                ElectronsVector({//TODO correct molecule geom?
                                        {Spin::alpha/*0*/,inbetween(nuclei.atoms(),{0,1},0.25)},
                                        {Spin::alpha/*1*/,inbetween(nuclei.atoms(),{1,5},0.25)},
                                        {Spin::alpha/*2*/,inbetween(nuclei.atoms(),{1,6},0.25)},
                                        {Spin::beta /*3*/,inbetween(nuclei.atoms(),{1,0},0.25)},
                                        {Spin::beta /*4*/,inbetween(nuclei.atoms(),{0,2},0.25)},
                                        {Spin::beta /*5*/,inbetween(nuclei.atoms(),{0,3},0.25)}
                                })};

        const MolecularGeometry doublyIonicAMix = {
                nuclei.atoms(),
                ElectronsVector({//TODO correct molecule geom?
                                        {Spin::alpha/*0*/,inbetween(nuclei.atoms(),{0,1},0.25)},
                                        {Spin::alpha/*1*/,inbetween(nuclei.atoms(),{1,6},0.25)},
                                        {Spin::alpha/*2*/,inbetween(nuclei.atoms(),{1,7},0.25)},
                                        {Spin::beta /*3*/,inbetween(nuclei.atoms(),{1,0},0.25)},
                                        {Spin::beta /*4*/,inbetween(nuclei.atoms(),{0,3},0.25)},
                                        {Spin::beta /*5*/,inbetween(nuclei.atoms(),{0,4},0.25)}
                                })};

        const MolecularGeometry doublyIonicBMix = {
                nuclei.atoms(),
                ElectronsVector({//TODO correct molecule geom?
                                        {Spin::beta /*3*/,inbetween(nuclei.atoms(),{1,0},0.25)},
                                        {Spin::alpha/*1*/,inbetween(nuclei.atoms(),{1,5},0.25)},
                                        {Spin::alpha/*2*/,inbetween(nuclei.atoms(),{1,6},0.25)},
                                        {Spin::alpha/*0*/,inbetween(nuclei.atoms(),{0,1},0.25)},
                                        {Spin::beta /*4*/,inbetween(nuclei.atoms(),{0,2},0.25)},
                                        {Spin::beta /*5*/,inbetween(nuclei.atoms(),{0,3},0.25)}
                                })};
    };


    namespace CoulombPotentialTest{
        const MolecularGeometry HeH = {
                AtomsVector({{Element::He,{0, 0,-1}},
                             {Element::H, {0, 0, 1}}}),
                ElectronsVector({{Spin::alpha,{0, 0,-1}},
                                 {Spin::alpha,{0, 0, 0}},
                                 {Spin::beta, {0, 0,-1}}})};
    }
}

#endif //INPSIGHTS_TESTMOLECULES_H
