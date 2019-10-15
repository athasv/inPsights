/* Copyright (C) 2019 Leonard Reuter.
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


#ifndef INPSIGHTS_IPOSITIONS_H
#define INPSIGHTS_IPOSITIONS_H

#include <ParticlesVector.h>

namespace YAML{
    Eigen::Vector3d decodePosition(const YAML::Node &node, const AtomsVector &nuclei);
}

#endif //INPSIGHTS_IPOSITIONS_H
