//
// Created by Moria on 19.05.2017.
//

#include "InputOutput.h"

InputOutput::InputOutput(const std::string &filename, bool isRead) {
    this->openFile(filename, isRead);
}

InputOutput::~InputOutput() {

}

void InputOutput::openFile(const std::string &filename, bool isRead) {
    this->filenames.push_back(filename);
    this->streams.emplace_back(filename,isRead?std::fstream::in:std::fstream::out);
}

void InputOutput::closeAllFiles() {

    for(std::vector<std::fstream>::iterator i=this->streams.begin();i!=this->streams.end();i++){
        (*i).close();
    }
    this->streams.clear();
    this->filenames.clear();
}
