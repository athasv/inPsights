/* Copyright 2020 Michael Heuer
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

#ifndef INPSIGHTS_SPINCORRELATIONVALUEDISTRIBUTION_H
#define INPSIGHTS_SPINCORRELATIONVALUEDISTRIBUTION_H

#include <Statistics.h>
#include <limits>

class SpinCorrelationValueDistribution { //TODO rename to histogram
public:
    SpinCorrelationValueDistribution(Eigen::Index oneSidedNonzeroBinCount = 25)
    :
    oneSidedNonzeroBinCount_(oneSidedNonzeroBinCount),
    binCount_(oneSidedNonzeroBinCount_ * 2 + 1),
    bins_(Eigen::VectorXd::Zero(binCount_)){};

    Eigen::Index calculateBinIndex(double spinCorrelation){
        auto binLength = 2.0 / static_cast<double>(binCount_);
        Eigen::Index binIndex = std::ceil(std::abs(spinCorrelation) / binLength - 0.5);
        return spinCorrelation >= 0 ? oneSidedNonzeroBinCount_ + binIndex : oneSidedNonzeroBinCount_ - binIndex;
    };

    void addSpinStatistic(const TriangularMatrixStatistics& spinCorrelations) {
        assert(spinCorrelations.mean().minCoeff() >= -1.0);
        assert(spinCorrelations.mean().maxCoeff() <= 1.0);

        for (Eigen::Index i = 0; i < spinCorrelations.rows()-1; ++i) {
            for (Eigen::Index j = i+1; j < spinCorrelations.cols(); ++j) {
                auto spinCorrelationValue = spinCorrelations.mean()(i,j);
                bins_[calculateBinIndex(spinCorrelationValue)]  += static_cast<double>(spinCorrelations.getTotalWeight());
            }
        }
    }

    Eigen::VectorXd getHistogramVector(){
        return bins_;
    };

private:
    Eigen::Index oneSidedNonzeroBinCount_,binCount_;
    Eigen::VectorXd bins_;

};

#endif //INPSIGHTS_SPINCORRELATIONVALUEDISTRIBUTION_H
