// Copyright (C) 2006-2008 Carnegie Mellon University (rdiankov@cs.cmu.edu)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
#include "plugindefs.h"
#include "ikbase.h"
#include "rave/plugin.h"

namespace herb2left {
#include "./leftarm_ikfast31_2011_02_17.cpp"
}
namespace herb2right {
#include "./rightarm_ikfast31_2011_02_17.cpp"
}

// register for typeof (MSVC only)
#ifdef RAVE_REGISTER_BOOST
#include BOOST_TYPEOF_INCREMENT_REGISTRATION_GROUP()
BOOST_TYPEOF_REGISTER_TYPE(herb2left::IKSolution)
BOOST_TYPEOF_REGISTER_TYPE(herb2right::IKSolution)
#endif

InterfaceBasePtr CreateInterfaceValidated(InterfaceType type, const std::string& name, std::istream& sinput, EnvironmentBasePtr penv)
{
    stringstream ss(name);
    string interfacename;
    ss >> interfacename;
    std::transform(interfacename.begin(), interfacename.end(), interfacename.begin(), ::tolower);

    switch(type) {
    case PT_InverseKinematicsSolver: {
        dReal freeinc = 0.04f;
        //ss >> freeinc;
        sinput >> freeinc;
        
        if( interfacename == "herb2leftikfast" ) {
            vector<int> vfree(herb2left::getNumFreeParameters());
            for(size_t i = 0; i < vfree.size(); ++i)
                vfree[i] = herb2left::getFreeParameters()[i];
            return InterfaceBasePtr(new IkFastSolver<herb2left::IKReal,herb2left::IKSolution>(herb2left::ik,vfree,freeinc,herb2left::getNumJoints(),(IkParameterization::Type)herb2left::getIKType(), boost::shared_ptr<void>(), herb2left::getKinematicsHash(), penv));
        }
        else if( interfacename == "herb2rightikfast" ) {
            vector<int> vfree(herb2right::getNumFreeParameters());
            for(size_t i = 0; i < vfree.size(); ++i)
                vfree[i] = herb2right::getFreeParameters()[i];
            return InterfaceBasePtr(new IkFastSolver<herb2right::IKReal,herb2right::IKSolution>(herb2right::ik,vfree,freeinc,herb2right::getNumJoints(),(IkParameterization::Type)herb2right::getIKType(), boost::shared_ptr<void>(), herb2right::getKinematicsHash(), penv));
        }

        break;
    }        
    default:
        break;
    }

    return InterfaceBasePtr();
}

void GetPluginAttributesValidated(PLUGININFO& info)
{
    // fill pinfo
    info.interfacenames[PT_InverseKinematicsSolver].push_back("Herb2Leftikfast");
    info.interfacenames[PT_InverseKinematicsSolver].push_back("Herb2Rightikfast");
}

RAVE_PLUGIN_API void DestroyPlugin()
{
}
