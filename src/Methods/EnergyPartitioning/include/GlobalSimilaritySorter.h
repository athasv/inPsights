//
// Created by Michael Heuer on 25.09.18.
//

#ifndef AMOLQCPP_GLOBALSIMILARITYSORTER_H
#define AMOLQCPP_GLOBALSIMILARITYSORTER_H

#include "Reference.h"
#include "Sample.h"
#include <Logger.h>
#include <HungarianHelper.h>
#include <spdlog/spdlog.h>
#include <vector>

class GlobalSimilaritySorter {
public:

    GlobalSimilaritySorter(
            std::vector<Sample>& samples,
            std::vector<Reference>& references,
            std::vector<SimilarReferences>& similarReferencesVector,
            double distThresh = 0.1)
            :
            samples_(samples),
            references_(references),
            similarReferencesVector_(similarReferencesVector),
            distThresh_(distThresh),
            increment_(std::abs((*references.rbegin()).value() * 1e-4)), //TODO appropriate range from stats
            console(spdlog::get(Logger::name))
    {
        if(!console){
            Logger::initialize();
            console = spdlog::get(Logger::name);
        };
    }

    bool sort(){
        if(references_.empty()) {
            console->error("References are empty.");
            return false;
        } else if (references_.size() == 1) {
            console->warn("No sorting because only one reference was found.");
            return true;
        }

        auto beginIt = references_.begin();

        if(similarReferencesVector_.empty()) {
            similarReferencesVector_.emplace_back(SimilarReferences(references_.begin()));
            beginIt++;
        }

        for (auto ref = beginIt; ref != references_.end(); ++ref) {
            bool isSimilarQ = false;

            std::vector<Reference> lowerRef = {Reference((*ref).value() - increment_)};
            std::vector<Reference> upperRef = {Reference((*ref).value() + increment_)};

            auto simRefLowerBoundIt = std::lower_bound(
                    similarReferencesVector_.begin(),
                    similarReferencesVector_.end(),
                    SimilarReferences(lowerRef.begin())); // return the first element that is < val
            auto simRefUpperBoundIt = std::upper_bound(
                    similarReferencesVector_.begin(),
                    similarReferencesVector_.end(),
                    SimilarReferences(upperRef.begin())); // return the first element that is > val

            auto totalLength = std::distance(similarReferencesVector_.begin(),similarReferencesVector_.end());
            auto lowerBoundDist = std::distance(similarReferencesVector_.begin(),simRefLowerBoundIt);
            auto upperBoundDist = std::distance(similarReferencesVector_.begin(),simRefUpperBoundIt);

            std::cout
            << std::distance(references_.begin(),ref) << "; "
            << "total length "
            << totalLength << " ["
            << (*similarReferencesVector_.begin()).representativeReference().value() << ","
            << (*similarReferencesVector_.rbegin()).representativeReference().value() << "], "
            << std::endl;
            std::cout << "lower bound dist: " << lowerBoundDist<< ", "
            << "upper bound dist: " << upperBoundDist<< ", "
            << std::endl;

            for (auto simRefs = simRefLowerBoundIt; simRefs != simRefUpperBoundIt; ++simRefs) {
                std::cout << (*simRefs).representativeReference().value() << std::endl;
                auto bestMatch = Metrics::bestMatch<Eigen::Infinity, 2>(
                        (*ref).maximum(),
                        (*simRefs).representativeReference().maximum());

                if (bestMatch.first < distThresh_) {
                    (*ref).permute(bestMatch.second, samples_);
                    (*simRefs).add(ref);
                    isSimilarQ = true;
                    break;
                }
            }
            if (!isSimilarQ) {
                similarReferencesVector_.emplace_back(SimilarReferences(ref));
            }
            std::sort(similarReferencesVector_.begin(),similarReferencesVector_.end());
        }
        return true;
    }

private:
    std::vector<Sample>& samples_;
    std::vector<Reference>& references_;
    std::vector<SimilarReferences>& similarReferencesVector_;
    double distThresh_, increment_;
    std::shared_ptr<spdlog::logger> console;
};


#endif //AMOLQCPP_GLOBALSIMILARITYSORTER_H
