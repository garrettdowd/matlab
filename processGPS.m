function [distance,elevation_angle] = processGPS(gps1,gps2,method)
%%%%%%%%%%%%%%%%%
% Dependencies:
%       haversine.m - https://www.mathworks.com/matlabcentral/fileexchange/27785-distance-calculation-using-haversine-formula
%
% gps1 and gps2 are arrays [latitude,longitude,elevation]
%       lat and long format is decimal degress or degrees,minutes,seconds 
%           [53.1472 -1.8494] or '52 12.16N, 000 08.26E'
%       elevation is in kilometers
%    gps1 OR gps2 can also be a static location [latitude,longitude,elevation]
%    If elevation is not given then it is assumed to be zero (however a
%      warning will be given)
%
% method
%       'pythagorean' computes the straight line distance using the 
%         pythagorean theorem. This straight line could travel "through" 
%         the earth if both points lie on the surface (elevation = 0).
%       'haversine' computes distance along surface of Earth (arc length on
%         ellipsoid). Good for long distances where arc length is more
%         accurate than a straight line connecting gps1 and gp2. 
%    WARNING - haversine method computes distance along surface of an
%      ellipsoid (Earth) which may lead to inaccurate or unwanted results
%      for large distances && large elevations
%
%
% distance is given in kilometers and is determined by chosen method
% elevation_angle from gps1 to gps2 in degrees
%
%
% Created by Garrett Dowd, 2018
% me@garrettdowd.com | garrettdowd.com
% Last updated on Nov. 30 2018 by Garrett Dowd
% With references to:
%   https://www.mkompf.com/gps/distcalc.html
%   https://www.mathworks.com/matlabcentral/fileexchange/27785-distance-calculation-using-haversine-formula
%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
% TO DO
%%%%%%%
% Enable azimuth angle calculations. Requires orientation/heading of radios
% 
%%%%%%%%%%%%%%%%%%

distance = [];
elevation_angle = [];

%% Input Checking

if size(gps1,2)>3 || size(gps1,2)<2
    error("ERROR. Input is bad. GPS1 data not correct size. Make sure that input "...
    +"is in column format and has correct number of columns")
end

if size(gps1,1)>size(gps2,1)
    if size(gps2,2)>1
        if size(gps2,2)~=size(gps1,1)>1 
            error("ERROR. Input is bad. GPS2 data not as long as GPS1")
        end
    end
else
    if size(gps1,1)>1
        if size(gps2,1)~=size(gps1,1)>1 
            error("ERROR. Input is bad. GPS1 data not as long as GPS2")
        end
    end
end

% check if lat and long are within bounds

% check if elevation makes sense
if size(gps1,2)>2
    if max(gps1(:,3))>11 && max(gps1(:,3))<400
        disp("GPS1 has elevation values above the crusing altitude of a 747. Are you sure your elevation has units of kilometers?")
    elseif max(gps1(:,3))>400
        error("GPS1 has elevation values at the orbiting altitude of the ISS. Make sure your elevation is in kilometers and not meters")
    end
end
if size(gps2,2)>2
    if max(gps2(:,3))>11 && max(gps2(:,3))<400
        disp("GPS2 has elevation values above the crusing altitude of a 747. Are you sure your elevation has units of kilometers?")
    elseif max(gps2(:,3))>400
        error("GPS2 has elevation values at the orbiting altitude of the ISS. Make sure your elevation is in kilometers and not meters")
    end
end
    
%% Input Processing

bigger=-1; %#ok<NASGU>
if size(gps1,1)==size(gps2,1)
    bigger = 0;
    n = size(gps1,1);
elseif size(gps1,1)>size(gps2,1)
    bigger = 1;
    n = size(gps1,1);
else
    bigger = 2;
    n = size(gps2,1);
end

if size(gps1,2)==2
    gps1(:,3) = zeros(n,1);
    disp("Assuming zero elevation for GPS1")
end

if size(gps2,2)==2
    gps2(:,3) = zeros(n,1);
    disp("Assuming zero elevation for GPS2")
end

distance = zeros(n,1);
elevation_angle = zeros(n,1);

%% Calculations

if strcmp(method,'pythagorean')
    for i=1:n
        if bigger==0
            j = i; % gps1 iteration
            k = i; % gps2 iteration
        elseif bigger==1
            % this means there is only one row in gps2
            j = i;
            k = 1;
        elseif bigger==2
            % this means there is only one row in gps1
            j = 1;
            k = i;
        else
            error("NOOOOO")
        end
        
        lat_diff = 111.3*(gps2(k,1) - gps1(j,1));
        lon_diff = 111.3*(gps2(k,2) - gps1(j,2));
        elv_diff = gps2(k,3) - gps1(j,3);
        x = lon_diff*cos((pi/180)*(gps1(j,1)+gps2(k,1))/2);
        y = lat_diff;
        z = elv_diff;
        distance(i,1) = (x^2 + y^2 + z^2)^.5;
        elevation_angle(i,1) = asind(elv_diff/distance(i,1));
    end
end

if strcmp(method,'haversine')
    for i=1:n
        if bigger==0
            j = i; % gps1 iteration
            k = i; % gps2 iteration
        elseif bigger==1
            % this means there is only one row in gps2
            j = i;
            k = 1;
        elseif bigger==2
            % this means there is only one row in gps1
            j = 1;
            k = i;
        else
            error("NOOOOO")
        end

        distance(i,1) = haversine(gps1(j,[1,2]),gps2(k,[1,2]));
        elv_diff = gps2(k,3)-gps1(j,3);
        elevation_angle(i,1) = atand(elv_diff/distance(i,1));
        % Calculate elevation adjusted distance using pythagorean
        distance(i,1) = (distance(i,1)^2 + elv_diff^2)^.5;
    end
end

