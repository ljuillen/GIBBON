function [varargout]=levelset2isosurface(L,controlPar)
% function [F,V,C]=levelset2isosurface(L,controlPar)
% ------------------------------------------------------------------------
%
% Change log:
% 2019/07/03 Added face (cap/other) color label output
% ------------------------------------------------------------------------

%% GET CONTROL PARAMETERS

kernelSize=3;

if isfield(controlPar,'contourLevel')    
    contourLevel=controlPar.contourLevel;
else %DEFAULT
    contourLevel=0; 
end

if isfield(controlPar,'voxelSize')    
    voxelSize=controlPar.voxelSize;   
else %DEFAULT
    voxelSize=[1 1 1];
end

if isfield(controlPar,'capOpt')    
    capOpt=controlPar.capOpt;
else %DEFAULT
    capOpt=1;
end

if isfield(controlPar,'nSub')    
    nSub=controlPar.nSub;
else %DEFAULT
    nSub=[1 1 1];
end

siz=size(L);

%% CREATE ISO-SURFACE

%Pad with zeros if desired
if capOpt==1
    Lpad=nanmax(L(:))*ones(size(L)+2*kernelSize);
    Lpad(1+kernelSize:siz(1)+kernelSize,1+kernelSize:siz(2)+kernelSize,1+kernelSize:siz(3)+kernelSize)=L;
    L=Lpad;
    siz=size(L);
end

% Get image coordinates
[J,I,K]=meshgrid(1:1:siz(2),1:1:siz(1),1:1:siz(3));
if capOpt==1
    I=I-kernelSize; J=J-kernelSize; K=K-kernelSize; %Correct for padding
end

%Convert to Cartesian coordinates using voxels size if provided
[X,Y,Z]=im2cart(I,J,K,voxelSize);

%Resample mesh and image
nNew=round(siz./nSub);
useRange_I=unique(round(linspace(1,siz(1),nNew(1))));
useRange_J=unique(round(linspace(1,siz(2),nNew(2))));
useRange_K=unique(round(linspace(1,siz(3),nNew(3))));

X_iso=X(useRange_I,useRange_J,useRange_K);
Y_iso=Y(useRange_I,useRange_J,useRange_K);
Z_iso=Z(useRange_I,useRange_J,useRange_K);
L_iso=L(useRange_I,useRange_J,useRange_K);

%Derive isosurface
[F,V] = isosurface(X_iso,Y_iso,Z_iso,L_iso,contourLevel);

%Clean isosurface
[F,V]=mergeVertices(F,V); %merge nodes
[~,indUni,~]=unique(sort(F,2),'rows'); %Check for unique faces
F=F(indUni,:); %Keep unique faces
[F,V]=patchCleanUnused(F,V); %Remove unused 
F=patchRemoveCollapsed(F); %remove collapsed (edges)
[F,V]=patchCleanUnused(F,V); %Remove unused points

%Derive caps
if capOpt==2
    [Fc,Vc] = isocaps(X_iso,Y_iso,Z_iso,L_iso,contourLevel);
%     Fc=Fc(:,[3 2 1]); %Flip face order so normal is outward

    F=patchRemoveCollapsed(F); %remove collapsed (edges)    
    [F,V]=patchCleanUnused(F,V); %Remove unused points
    
    %Join and patch data
    C=[ones(size(F,1),1);2*ones(size(Fc,1),1)]; %Face label data
    F=[F;Fc+size(V,1);]; %Faces    
    V=[V;Vc;]; %Vertices
    
    %Merge vertices
    [F,V]=mergeVertices(F,V);
else
    C=ones(size(F,1),1);
end

if capOpt>0
    % remove "flag" triangles
    while 1
        C=patchConnectivity(F,V,{'ef'});
        EF=C.edge.face;        
        logicRemove= (sum(EF>0,2)==1);        
        if nnz(logicRemove)==0
            break
        end
        indRemove=unique(EF(logicRemove,:));
        indRemove=indRemove(indRemove>0);
        logicKeep=true(size(F,1),1);
        logicKeep(indRemove)=0;
        
        F=F(logicKeep,:);
        [F,V]=patchCleanUnused(F,V);
    end
end

%% Collect output
varargout{1}=F;
varargout{2}=V;
varargout{3}=C;

%% 
% _*GIBBON footer text*_ 
% 
% License: <https://github.com/gibbonCode/GIBBON/blob/master/LICENSE>
% 
% GIBBON: The Geometry and Image-based Bioengineering add-On. A toolbox for
% image segmentation, image-based modeling, meshing, and finite element
% analysis.
% 
% Copyright (C) 2019  Kevin Mattheus Moerman
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
