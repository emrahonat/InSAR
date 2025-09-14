%% SAR Interferometry
% 
% 1 - Guide Map Generation
% 2 - Phase Unwrapping
%
% Dr. Emrah Onat
% 14.09.2025
% 

%

clear all
close all
clc

%% Display
disp('--- Algorithms ---');

fid = fopen( 'results.txt', 'wt' );
fprintf( fid, '%3s %13s %8s %8s %10s %10s %10s %10s\r\n','#i', '#Input','#Map', '#PUAlg','Duration', '#Residue', '#BranchCut', 'RMSE');

iteration = 0;
for i = 10:10
%     fprintf( fid, '%61s\r\n','------------------------------------------------------------');
    %% Input Images
    % 1 - P00 - ifsar.512x512
    % 2 - P00 - head.256x256
    % 3 - P00 - knee.256x256
    % 4 - PCS - longs.152x458
    % 5 - PCS - isola.157x458
    % 6 - P0S - shear.257x257
    % 7 - P0S - spiral.257x257
    % 8 - P00 - noise.257x257
    % 9 - P00 - peaks.101x101
    % 10 -P0S - noisypeaks.101x101
    % 11 -P00 - volcano.1591x561
    % 12 -P0S - gaussele.100x100
    % 13 -P0S - gaussmask.150x100
    % 14 -P0S - gaussmask2.150x100
    % 15 -P00 - numphant.150x100
    
    numberofinputimage = i;
    [Inpimage, phaseimage, maskimage, corrimage, surfimage] = inputexamples(numberofinputimage, fid);
    
    figure;
    subplot(311);imagesc(phaseimage);title(['Input Phase Image, #Map = ' num2str(numberofinputimage)]);
    subplot(312);imagesc(corrimage);title('Input Correlation Map');
    subplot(313);mesh(surfimage);title('Groundtruth Unwrapped Map');

    for j = 1:1
        %% Guided Map Generation
        % 0 - No Map
        % 1 - Correlation Map
        % 2 - PseudoCorrelation Map
        % 3 - Phase Derivative Variance Map
        % 4 - Maximum Phase Variance Map
        % 5 - Ampherence Map
        
        numberofQualAlgo = j;
        [MAPtype, qualmap, average_val] = QualMapGen(numberofQualAlgo, phaseimage, corrimage, maskimage, fid);
        figure;imagesc(qualmap);title(['Guide Map, Average Value = ' num2str(average_val) ', Map Number = ' num2str(numberofQualAlgo)]);

        for k = 12:12
            %% Phase Unwrapping Algorithms
            % 0 - Itoh Matlab
            % 1 - Goldstein Matlab
            % 2 - Goldstein C/C++
            % 3 - Quality Guided Matlab
            % 4 - Quality Guided C/C++
            % 5 - Mask Cut C/C++
            % 6 - Flynn C/C++
            % 7 - PUMA
            % 8 - SPUD
            % 9 - fp-Matlab
            % 10 - fp-wff-Matlab
            % 11 - fp-wfr-Matlab
            % 12 - Constantinini
            % 13 - 2D-SRNCP
            % 14 - 2D-SRNCP-V2
            % 15 - Unweighted LS
            
            if k==7 && (i==5 || i== 6 || i==7 || i==8 || i==1 || i==11)
                continue;
            end
            if k==6 && (i==10)
                continue;
            end
            if k==3 
                continue;
            end

            numberofPUAlgo = k;
            tic;
            [PUAlg, resmap, BCmap, unwrappedmap] = PUalgorithms(numberofPUAlgo, phaseimage, maskimage, qualmap);
            duration = toc;
            resnumber = length(find(resmap));
            BClength = sum(sum(BCmap));
            unwrappedmap = unwrappedmap-min(min(unwrappedmap)); unwrappedmap = unwrappedmap/max(max(unwrappedmap)); 
            surfimage = surfimage-min(min(surfimage)); surfimage = surfimage/max(max(surfimage)); 
            rmse_uW = rms(rms(surfimage-unwrappedmap));
            
            figure
            subplot(321);imagesc(phaseimage);title(['Input Phase Image, #Input = ' Inpimage]);
            subplot(322);imagesc(qualmap);title(['Guide Map, Avg Val = ' num2str(average_val) ', #Map = ' MAPtype]);
            subplot(323);imagesc(resmap);title(['Residue Map, #Res = ' num2str(resnumber)]);
            subplot(324);imagesc(BCmap);title(['Branch-Cut Map, length = ' num2str(BClength)]);
            subplot(325);imagesc(unwrappedmap);title(['Unwrapped Map, RMSE = ' num2str(rmse_uW)]);
            subplot(326);mesh(unwrappedmap);title(['Unwrapped Map, PU Algo = ' PUAlg]);
            
            iteration = iteration +1;
            A = [iteration; i; j; k; resnumber; BClength; rmse_uW; duration];

            fprintf( fid, '%3d %13s %8s %8s %10f %10d %10d %10f\r\n', iteration, Inpimage, MAPtype, PUAlg, duration, resnumber, BClength, rmse_uW);
%             fprintf( fid, '%5s \r\n', PUAlg);
        end
    end
end

fclose(fid);
open('results.txt');