/* Copyright (C) 2020 Michael Heuer.
 *
 * This file is part of inPsights.
 * inPsights is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * inPsights is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with inPsights. If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef INPSIGHTS_LOCALPARTICLEENERGIESCALCULATION_H
#define INPSIGHTS_LOCALPARTICLEENERGIESCALCULATION_H

#include <Statistics.h>
#include <Sample.h>
#include <Cluster.h>
#include <ParticleSelection.h>
#include <EnergyResultsBundle.h>

class LocalParticleEnergiesCalculator {
public:
    struct LocalEnergyResults {
        SingleValueStatistics selected, rest, inter;
    };

    struct LocalBondEnergyResults {
        SingleValueStatistics intraBondAndInterCoresBond,intraBond, intraRest, interBondRest;
        VectorStatistics intraCores, interCoresBond, interCoresRest;
        TriangularMatrixStatistics interCoresCore;
    };

    LocalParticleEnergiesCalculator(
            const std::vector<Sample> &samples,
            const AtomsVector &atoms,
            const std::vector<size_t> &nucleiIndices,
            size_t selectedElectronsCount);

    void add(const Cluster &cluster);

    const std::vector<Sample> &samples_;
    std::vector<size_t> selectedNucleiIndices_;
    size_t selectedElectronsCount_;

    EnergyResultsBundle<LocalEnergyResults> localEnergies;
    EnergyResultsBundle<LocalBondEnergyResults> localBondEnergies;


    void selectedRestInter(const Cluster &cluster, size_t numberOfElectrons, const AtomsVector &permutedNuclei,
            const Eigen::MatrixXd &VnnMat);

    void bondEnergyCalculation(const Cluster &cluster, size_t numberOfElectrons, const AtomsVector &permutedNuclei,
                               const Eigen::MatrixXd &VnnMat) ;

    void createIndiceLists(size_t numberOfElectrons, const AtomsVector &permutedNuclei,
                           std::vector<size_t> &selectedElectronIndices, std::vector<size_t> &remainingElectronIndices,
                           std::vector<size_t> &remainingNucleiIndices) const;
};

namespace YAML {
    class Emitter;

    Emitter& operator<< (Emitter& out, const LocalParticleEnergiesCalculator::LocalEnergyResults& rhs);
    Emitter& operator<< (Emitter& out, const LocalParticleEnergiesCalculator::LocalBondEnergyResults& rhs);

    Emitter& operator<< (Emitter& out, const LocalParticleEnergiesCalculator& rhs);
}


#endif //INPSIGHTS_LOCALPARTICLEENERGIESCALCULATION_H
