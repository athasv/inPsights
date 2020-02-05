/* Copyright 2020 heuer
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

#ifndef INPSIGHTS_GRAPHCLUSTERER_H
#define INPSIGHTS_GRAPHCLUSTERER_H

#include "Sample.h"
#include "IClusterer.h"
#include <ISettings.h>

namespace Settings {
    class GraphClusterer : public ISettings {
    public:
        Property<double> startRadius = {0.0, VARNAME(startRadius)};
        Property<double> endRadius = {1.0, VARNAME(endRadius)};
        Property<double> radiusIncrement = {0.05, VARNAME(radiusIncrement)};
        Property<double> minimalWeight = {0.0, VARNAME(minimalWeight)};

        GraphClusterer();
        explicit GraphClusterer(const YAML::Node &node);
        void appendToNode(YAML::Node &node) const override;
    };
}
YAML_SETTINGS_DECLARATION(Settings::GraphClusterer)
class GraphClusterer : public IClusterer{
public:
    static Settings::GraphClusterer settings;

    GraphClusterer(Group& group);
    Eigen::MatrixXd calculateAdjacencyMatrix(Group& group);
    void cluster(Group& group) override;
    std::vector<std::size_t> scanClusterSizeWithDistance(const Group& group);
    std::vector<double> scanTotalWeightDifferenceWithDistance(const Group& group);

private:
    //std::vector<Sample> &samples_;
    Eigen::MatrixXd mat_;
};

template<typename K, typename V>
bool findByValue(std::vector<K> & vec, std::map<K, V> mapOfElemen, V value)
{
    bool bResult = false;
    auto it = mapOfElemen.begin();
    // Iterate through the map
    while(it != mapOfElemen.end())
    {
        // Check if value of this entry matches with given value
        if(it->second == value)
        {
            // Yes found
            bResult = true;
            // Push the key in given map
            vec.push_back(it->first);
        }
        // Go to next entry in map
        it++;
    }
    return bResult;
}

#endif //INPSIGHTS_GRAPHCLUSTERER_H
