clc
close all
clearvars


%% Test


% T = readtable('2018_Crime_Datafloortimelatlong_40x40.csv');
% h = heatmap(T,'x3','x4');
% k = 1;
% array = cell(1,40);
% array2 = cell(1,40);
% for i = 40:-1:1
%     array(k) = cellstr(int2str(i));
%     n = 41-k;
%     array2(n) = cellstr(int2str(i));
%     k = k+1;
% end
% h.YDisplayData = array;
% h.XDisplayData = array2;

%% 

% for j = 1:5
%     resttable = T(T.x1 == j, :);  %select only those rows that are j and all columns
%     figure(j+1)
%     h = heatmap(resttable,'x3','x4');
%     h.Colormap = parula;
%     h.Title = strcat('Crime Matrix for Hour ',int2str(j));
%     h.YDisplayData = array;
%     h.XDisplayData = array2;
% end



%% Actual crime matrices

clc
close all
clearvars

P1 = xlsread('PMatrixWeighted0.005Hour1.csv');
P2 = xlsread('PMatrixWeighted0.005Hour2.csv');
P3 = xlsread('PMatrixWeighted0.005Hour3.csv');
C1 = xlsread('CMatrixHour1.csv');
C2 = xlsread('CMatrixHour2.csv');
C3 = xlsread('CMatrixHour3.csv');
testb = xlsread('Demo Data.xlsx');
testa1 = xlsread('Demo Data after.xlsx');
testa2 = xlsread('Demo Data after2.xlsx');
figure(1)
colormap('parula');   % set colormap
imagesc(P2);        % draw image and scale colormap to values range  
set(gca,'YDir','normal');
colorbar;% show color scale
title('Police Matrix at the Start of Hour 2');
xlabel('Latitude');
ylabel('Longitude');
caxis manual
caxis([0 0.026]);

figure(2)
colormap('parula');   % set colormap
imagesc(P3);        % draw image and scale colormap to values range
set(gca,'YDir','normal');
colorbar;          % show color scale
title('Police Matrix at the End of Hour 2/Start of Hour 3');
xlabel('Latitude');
ylabel('Longitude');

figure(3)
colormap('parula');   % set colormap
imagesc(C1);        % draw image and scale colormap to values range
set(gca,'YDir','normal');
colorbar;          % show color scale
title('Crime Matrix for Hour 1');
xlabel('Latitude');
ylabel('Longitude');

figure(4)
colormap('parula');   % set colormap
imagesc(C2);        % draw image and scale colormap to values range
set(gca,'YDir','normal');
colorbar;          % show color scale
title('Crime Matrix for Hour 2');
xlabel('Latitude');
ylabel('Longitude');



figure(6)
colormap('parula');   % set colormap
imagesc(testb);        % draw image and scale colormap to values range
set(gca,'YDir','normal');
colorbar;          % show color scale
title('Action Demonstration: Initial State');
xlabel('Latitude');
ylabel('Longitude');
caxis manual
caxis([-0.5 0.3]);

figure(7)
colormap('parula');   % set colormap
imagesc(testa1);        % draw image and scale colormap to values range
set(gca,'YDir','normal');
colorbar;          % show color scale
title('Action Demonstration: After 1 Action');
xlabel('Latitude');
ylabel('Longitude');
caxis manual
caxis([-0.5 0.3]);

figure(8)
colormap('parula');   % set colormap
imagesc(testa2);        % draw image and scale colormap to values range
set(gca,'YDir','normal');
colorbar;          % show color scale
title('Action Demonstration: After 2 Actions');
xlabel('Latitude');
ylabel('Longitude');
caxis manual
caxis([-0.5 0.3]);


figure(10)
colormap('parula');   % set colormap
imagesc(P3-C2);        % draw image and scale colormap to values range
set(gca,'YDir','normal');
colorbar;          % show color scale
title('S Matrix for end of Hour 2');
xlabel('Latitude');
ylabel('Longitude');