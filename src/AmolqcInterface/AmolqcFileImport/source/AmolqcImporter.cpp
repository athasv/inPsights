/* Copyright (C) 2017-2019 Michael Heuer.
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

#include <AmolqcImporter.h>

AmolqcImporter::AmolqcImporter(const std::string &filename)
        : Importer(filename) {}

PositionsVector AmolqcImporter::importPositionsVectorBlock(unsigned long startLineIdx,
                                                                 unsigned long startLineElement,
                                                                 unsigned long numberOfPositions) const {
    PositionsVector positionsVector;
    for (unsigned long i = 0; i < numberOfPositions; ++i) {
        std::vector<std::string> lineElements = split(getLine(startLineIdx+i));
        double x = std::stod(lineElements[startLineElement+0]);
        double y = std::stod(lineElements[startLineElement+1]);
        double z = std::stod(lineElements[startLineElement+2]);

        positionsVector.append(Eigen::Vector3d(x,y,z));
    }
    return positionsVector;
}

std::vector<SubstructureDataEntry>
AmolqcImporter::countSubstructures(unsigned long startLineIdx, unsigned long blockLength) const {

    std::vector<SubstructureDataEntry> substructuresData;

    unsigned long sumOfMaximaNumbersTillCurrent = 0;
    unsigned long sumOfMaximaNumbersWithCurrent = 0;

    unsigned long currentLineIdx = startLineIdx;
    std::string currentLine = getLine(currentLineIdx);
    unsigned long firstLineOfSuperstructure = currentLineIdx;

    unsigned long k = 0;
    unsigned long m = 0;
    unsigned long k_last = 1;
    unsigned long m_last = 1;

    while (!currentLine.empty()){
        std::vector<std::string> currentLineElements = split(currentLine);
        k = std::stoul(currentLineElements[1]);
        m = std::stoul(currentLineElements[2]);

        // if new superstructure reached
        if ( k > k_last){
            sumOfMaximaNumbersWithCurrent = std::stoul(currentLineElements[6]);

            substructuresData.emplace_back(
                    SubstructureDataEntry(firstLineOfSuperstructure, m_last, sumOfMaximaNumbersTillCurrent));
            firstLineOfSuperstructure = currentLineIdx;
            k_last = k;
            m_last = 1;
        }
            // else currentLine contains another substructure
        else {
            sumOfMaximaNumbersWithCurrent = sumOfMaximaNumbersTillCurrent;
            sumOfMaximaNumbersWithCurrent += std::stoul(currentLineElements[6]);
            m_last = m;
        };

        currentLineIdx +=  blockLength;
        if( currentLineIdx >= lines_.size())
            break;
        currentLine = getLine(currentLineIdx);
        sumOfMaximaNumbersTillCurrent = sumOfMaximaNumbersWithCurrent;
    }
    // add last superstructure
    if (k > 0){
        substructuresData.emplace_back(
                SubstructureDataEntry(firstLineOfSuperstructure, m_last, sumOfMaximaNumbersTillCurrent));
    }
    return substructuresData;
}
