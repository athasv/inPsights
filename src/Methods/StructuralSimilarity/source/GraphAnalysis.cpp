/* Copyright (C) 2019 Michael Heuer.
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

#include <GraphAnalysis.h>
#include <numeric>
#include <Enumerate.h>

namespace GraphAnalysis {
    Eigen::MatrixXb filter(const Eigen::MatrixXd & matrix, double threshold) {
        assert( (matrix.array() >= 0.0).all() );
        assert( threshold >= 0.0);

        assert( (matrix.array() <= 1.0).all() );
        assert( threshold <= 1.0);

        return matrix.unaryExpr([&](const double x) { return (x >= threshold) ? 1.0 : 0.0; }).cast<bool>();
    }

    Eigen::MatrixXb lowerOrEqualFilter(const Eigen::MatrixXd & matrix, double threshold) {
        assert( (matrix.array() >= 0.0).all() );
        assert( threshold >= 0.0);

        return matrix.unaryExpr([&](const double x) { return (x <= threshold) ? 1.0 : 0.0; }).cast<bool>();
    }

    std::list<Eigen::Index> findConnectedVertices(const Eigen::MatrixXb &adjacencyMatrix, Eigen::Index startVertex) {
        assert(adjacencyMatrix.rows() == adjacencyMatrix.cols());

        Eigen::Index vertexCount = adjacencyMatrix.rows();
        assert(vertexCount > 0);
        assert(startVertex < vertexCount);

        Eigen::VectorXb marks = Eigen::VectorXb::Constant(vertexCount, 1, false);
        marks(startVertex) = true;


        std::queue<Eigen::Index> queue;
        queue.push(startVertex);

        // breadth first search
        while (!queue.empty()) {
            for (Eigen::Index i = 0; i < vertexCount; ++i)
                if (adjacencyMatrix(queue.front(), i) && !marks(i)) {
                    marks(i) = true;
                    queue.push(i);
                }
            queue.pop();
        }

        std::list<Eigen::Index> connectedVertices;

        for (Eigen::Index i = 0; i < vertexCount; ++i)
            if (marks(i)) connectedVertices.push_back(i);

        return connectedVertices;
    }

    // returns a vector of lists containing
    std::vector<std::list<Eigen::Index>> findGraphClusters(const Eigen::MatrixXb &adjacencyMatrix) {
        assert(adjacencyMatrix.rows() == adjacencyMatrix.cols());

        Eigen::Index vertexCount = adjacencyMatrix.rows();
        assert(vertexCount > 0);

        // create
        std::list<Eigen::Index> remainingVertices(vertexCount);
        std::iota(remainingVertices.begin(), remainingVertices.end(), 0);

        std::vector<std::list<Eigen::Index>> clusters;

        while (!remainingVertices.empty()) {
            // breadth-first search of connected vertices in the adjacency matrix
            // starting at the first of the remaining vertices
            auto connectedVertices = findConnectedVertices(adjacencyMatrix, remainingVertices.front());
            clusters.push_back(connectedVertices);

            std::list<Eigen::Index> difference;

            // determine remaining vertices from the difference to the newly found connected vertices
            std::set_difference(
                    remainingVertices.begin(), remainingVertices.end(),
                    connectedVertices.begin(), connectedVertices.end(), std::back_inserter(difference));
            remainingVertices = difference;
        };

        return clusters;
    }
}

std::map<Eigen::Index, Eigen::Index> GraphAnalysis::findMergeMap(
        std::vector<std::list<Eigen::Index>> subsets,
        std::vector<std::list<Eigen::Index>> referenceSets
){
    // identify, which sets are subsets of the previous ones
    std::map<Eigen::Index, Eigen::Index> map;

    for(const auto & [currentClusterIndex, currentCluster]  : enumerate(referenceSets)){
        for(const auto & [prevClusterIndex, prevCluster] : enumerate(subsets)){
            auto isSubsetQ = std::includes(
                    currentCluster.begin(), currentCluster.end(),
                    prevCluster.begin(), prevCluster.end());
            if(isSubsetQ)
                map[prevClusterIndex] = currentClusterIndex;
        }
    }
    return map;
};