% Copyright (c) 2010 Carnegie Mellon University and Intel Corporation
%   Author: Dmitry Berenson <dberenso@cs.cmu.edu>
%
%   Redistribution and use in source and binary forms, with or without
%   modification, are permitted provided that the following conditions are met:
%
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of Intel Corporation nor Carnegie Mellon University,
%       nor the names of their contributors, may be used to endorse or
%       promote products derived from this software without specific prior
%       written permission.
%
%   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%   ARE DISCLAIMED. IN NO EVENT SHALL INTEL CORPORATION OR CARNEGIE MELLON
%   UNIVERSITY BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
%   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
%   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
%   OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
%   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
%   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
%   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%An example of TSR chaining for reaching for a bottle
%This example uses two TSR Chains, each of length 1, to define the allowable goal end-effector poses
clear all;
close all;

%load the environment
orEnvLoadScene('../../ormodels/environments/intelkitchen_robotized_herb2.env.xml',1);
objectid = orEnvCreateKinBody('bottle','../../ormodels/objects/household/juice_bottle_model.kinbody.xml');
T0_object = MakeTransform(eye(3),[0.3602  0.2226 0.9214]');
orBodySetTransform(objectid, [GetRot(T0_object) GetTrans(T0_object)]');

robotid = orEnvGetBody('BarrettWAM');

%set printing and display options
orEnvSetOptions('debug 3')
orEnvSetOptions('collision ode')

%create problem instances 
probs.cbirrt = orEnvCreateProblem('CBiRRT','BarrettWAM');

%get the descriptions of the robot's manipulators
manips = orRobotGetManipulators(robotid);

%define joint indices
jointdofs = 0:orRobotGetActiveDOF(robotid);
activedofs = [manips{1}.armjoints];

%start the robot in a reasonable location and configuration
orBodySetTransform(robotid,[-0.0024,1,0,-1,-0.0024,0,0,0,1, 0.274, -0.6, 0.000]');
initdofvals = [3.68,   -1.9,   -0.0000,    2.2022,   -0.0000,    0.0000,    -2.1, 2.6,  -1.9,   -0.0000,    2.2022,   -3.14,   0.0000,    -1.0];
orRobotSetDOFValues(robotid,initdofvals,[manips{1}.armjoints manips{2}.armjoints]);

%set the active dof
orRobotSetActiveDOFs(robotid,activedofs);

%close the fingers
handdof = 0.5*ones(1,3);
orRobotSetDOFValues(robotid,handdof,manips{1}.handjoints);

%let's define two TSR chains for this task, they differ only in the rotation of the hand

%first TSR chain

%place the first TSR's reference frame at the object's frame relative to world frame
T0_w = T0_object;

%get the TSR's offset frame in w coordinates
Tw_e1 = MakeTransform(rodrigues([pi/2 0 0]),[0 0.20 0.1]');

%define bounds to only allow rotation of the hand about z axis and a small deviation in translation along the z axis
Bw = [0 0   0 0   -0.02 0.02   0 0   0 0   -pi pi];

TSRstring1 = SerializeTSR(0,'NULL',T0_w,Tw_e1,Bw);
TSRChainString1 = SerializeTSRChain(0,1,0,1,TSRstring1,'NULL',[]);

%now define the second TSR chain
%it is the same as the first TSR Chain except Tw_e is different (the hand is rotated by 180 degrees about its z axis)
Tw_e2 = MakeTransform(rodrigues([0 pi 0])*rodrigues([pi/2 0 0]),[0 0.20 0.1]');

TSRstring2 = SerializeTSR(0,'NULL',T0_w,Tw_e2,Bw);
TSRChainString2 = SerializeTSRChain(0,1,0,1,TSRstring2,'NULL',[]);

%call the cbirrt planner, it will generate a file with the trajectory called 'cmovetraj.txt'
orProblemSendCommand(['RunCBiRRT psample 0.25 ' TSRChainString1 ' '  TSRChainString2],probs.cbirrt);

%execute the trajectories generated by the planner
orProblemSendCommand(['traj cmovetraj.txt'],probs.cbirrt);
orEnvWait(1);
