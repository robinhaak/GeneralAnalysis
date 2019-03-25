function [vecMean,vecSEM] = doPEP(vecTimestamps,vecTraceOrWindow,vecEvents,sOptions)
	%doPEP Performs Peri-Event Plot of supplied trace
	%syntax: [vecMean,vecSEM] = doPEP(vecTimestamps,vecTraceOrWindow,vecEvents,sOptions)
	%	input:
	%	- vecTimestamps; timestamps of data in vecTrace (for spikes: spike times)
	%	- vecTraceOrWindow; trace containing data to be plotted (for spikes: binning edges for window)
	%	- vecEvents; vector containing events to plot around
	%	- sOptions, structure containing the following fields:
	%		- handleFig; handle to figure (set to -1 to suppress plotting)
	%		- vecColor; 3-element vector specifying line color
	%		- vecWindow; 2-element vector specifying which time window in
	%			seconds to plot around events [default; [-1 +3]]
	%
	%Version history:
	%1.0 - August 1 2013
	%	Created by Jorrit Montijn
	%2.0 - Feb 5 2019
	%	Split doPEP into two functions that are easier to use [by JM].
	%	For future reference, prior syntax was:
	%		cellHandles = doPEP(sEvents,vecTrace,vecTrace2)
	%	Other changes include: use of alpha-mapping for transparency by
	%	updating errorfill(), addition of time-stamp vector as input,
	%	general simplifications wrt code and input arguments
	%2.1 - Feb 8 2019
	%	Added support for time-stamp based input (e.g., spike times) and
	%	updated syntax and help somewhat [by JM]
	
	
	%% get inputs
	if ~exist('sOptions','var'),sOptions=struct;end
	if isfield(sOptions,'vecColor'), vecColor = sOptions.vecColor; else, vecColor=[0 0 1]; end
	if isfield(sOptions,'handleFig'), handleFig = sOptions.handleFig;else, handleFig = [];end
	
	
	%% plot peri-event trace
	if numel(vecTraceOrWindow) < numel(vecTimestamps)
		%% input is spike times
		%get window
		intWindowSize = numel(vecTraceOrWindow)-1;
		vecBinDur = diff(vecTraceOrWindow);
		vecWindowBinCenters = vecTraceOrWindow(1:(end-1)) + vecBinDur/2;
		
		%get event times
		intEvents = numel(vecEvents);
		
		%go through event loop
		matPET = nan(intEvents,intWindowSize);
		for intEvent=1:intEvents
			%retrieve target entries
			vecTheseEdges = vecTraceOrWindow + vecEvents(intEvent);
			[vecCounts,edges] = histcounts(vecTimestamps,vecTheseEdges);
			matPET(intEvent,:) = vecCounts./vecBinDur;
		end
		
	elseif numel(vecTraceOrWindow) == numel(vecTimestamps)
		%% input is trace
		%get window
		if isfield(sOptions,'vecWindow'), vecWindow = sOptions.vecWindow;else, vecWindow = [-1 3];end
		%get event times
		intEvents = numel(vecEvents);
		vecEventStarts = vecWindow(1) + vecEvents;
		vecEventStops = vecWindow(2) + vecEvents;
		
		%get window variables
		intWindowSize = 1 + find(vecTimestamps >= vecEventStops(2),1) - find(vecTimestamps >= vecEventStarts(2),1);
		vecWindowBinCenters = (0:(intWindowSize-1))/(intWindowSize-1);
		vecWindowBinCenters = (vecWindowBinCenters * range(vecWindow)) + vecWindow(1);
		
		%use simple trial loop
		matPET = nan(intEvents,intWindowSize);
		for intEvent=1:intEvents
			%retrieve target entries
			vecAssignPoints = 1:intWindowSize;
			intStart = find(vecTimestamps >= vecEventStarts(intEvent),1);
			intStop = find(vecTimestamps >= vecEventStops(intEvent),1);
			if isempty(intStop) %out-of-bounds at end
				intStop=numel(vecTimestamps);
				vecUsePoints = intStart:intStop;
				vecAssignPoints((numel(vecUsePoints)+1):end) = []; %remove out-of-bounds entries
			end
			if intStart == 1 %out-of-bounds at start
				vecUsePoints = intStart:intStop;
				intDeleteUpTo = numel(vecAssignPoints)-numel(vecUsePoints);
				if intDeleteUpTo>0
					vecAssignPoints(1:intDeleteUpTo) = []; %remove out-of-bounds entries
				end
			end
			
			%assign data to matrix
			vecUsePoints = intStart:intStop;
			matPET(intEvent,vecAssignPoints) = vecTraceOrWindow(vecUsePoints);
		end
		
		
	else
		%% input is wrong
		error([mfilename ':WrongSyntax'],'Incorrect input, syntax is: [vecMean,vecSEM] = doPEP(vecTimestamps,vecTraceOrWindow,vecEvents,sOptions)');
	end
	
	%% get mean + sem
	vecMean = nanmean(matPET,1);
	vecSEM = nanstd(matPET,[],1)/sqrt(intEvents);
	
	%% plot
	if isempty(handleFig)
		figure;
	end
	if handleFig == -1
		return;
	else
		errorfill(vecWindowBinCenters, vecMean, vecSEM, vecColor);
	end
	
	%{
	vecSelectInv = intWindowSize:-1:1;
	
	%% plot shade
	if ~isempty(handleFig),figure(handleFig);end
	hold on
	hShade = fill([vecPlotX vecPlotX(vecSelectInv)],[vecMean-vecSEM vecMean(vecSelectInv)+vecSEM(vecSelectInv)],vecColor,'EdgeColor','none');
	alpha(hShade,.5);
	
	%% plot line
	plot(vecPlotX,vecMean,'-','LineWidth',2,'Color',vecColor);
	hold off;
	drawnow;
	%}
end
