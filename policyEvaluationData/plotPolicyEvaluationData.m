%% Script to plot policyEvaluation data
clc
clear all
close all
policyEvaluation0_001 =importfile('policyEvaluationForWeightedCrime0.001.txt', 1, 305);
policyEvaluation0_01 =importfile('policyEvaluationForWeightedCrime0.01.txt', 1, 133);
policyEvaluation0_03 =importfile('policyEvaluationForWeightedCrime0.03.txt', 1, 15);
policyEvaluation0_005 =importfile('policyEvaluationForWeightedCrime0.005.txt', 1, 216);

color1=[0, 0.4470, 0.7410];
color2=[0.8500, 0.3250, 0.0980]	;
color3=[0.9290, 0.6940, 0.1250]	;
color4=[0.4940, 0.1840, 0.5560]	;
color5=[0.4660, 0.6740, 0.1880]	;
color6=[0.3010, 0.7450, 0.9330]	;
color7=[0.6350, 0.0780, 0.1840]	;

figure
plot(policyEvaluation0_001(:,1),policyEvaluation0_001(:,2),'Color',color1,'LineWidth', 2)
hold on
plot(policyEvaluation0_005(:,1),policyEvaluation0_005(:,2),'Color',color2,'LineWidth', 2)
hold on
plot(policyEvaluation0_01(:,1),policyEvaluation0_01(:,2),'Color',color3,'LineWidth', 2)
hold on
plot(policyEvaluation0_03(:,1),policyEvaluation0_03(:,2),'Color',color4,'LineWidth', 2)
legend({'Threshold= -0.001','Threshold= -0.005','Threshold= -0.01','Threshold= -0.03'},'FontSize',20)
xlabel('Timestep (hours)','FontSize',20)
ylabel('Policy evaluation score','FontSize',20)
title('Policy evaluation for different thresholds','FontSize',24)
xlim([0 24])
set(gca,'XTick',0:1:24)
grid on
