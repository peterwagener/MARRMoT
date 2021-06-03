function [val,c,w,idx] = of_inverse_KGE(obs, sim, idx, w)
% of_inverse_KGE Calculates Kling-Gupta Efficiency of the inverse of
% simulated streamflow (Gupta et al, 2009), intended to capture low flow
% aspects better (Pushpalatha et al, 2012). Ignores time steps with -999 
% values.
%
% Copyright (C) 2018 W. Knoben
% This program is free software (GNU GPL v3) and distributed WITHOUT ANY
% WARRANTY. See <https://www.gnu.org/licenses/> for details.
%
% In:
% obs       - time series of observations       [nx1]
% sim       - time series of simulations        [nx1]
% idx       - optional vector of indices to use for calculation, can be
%               logical vector [nx1] or numeric vector [mx1], with m <= n
% w         - optional weights of components    [3x1]
%
% Out:
% val       - objective function value          [1x1]
% c         - components [r,alpha,beta]         [3x1]
% idx       - indices used for the calculation
% w         - weights    [wr,wa,wb]             [3x1]
%
% Gupta, H. V., Kling, H., Yilmaz, K. K., & Martinez, G. F. (2009). 
% Decomposition of the mean squared error and NSE performance criteria: 
% Implications for improving hydrological modelling. Journal of Hydrology, 
% 377(1–2), 80–91. https://doi.org/10.1016/j.jhydrol.2009.08.003
%
% Pushpalatha, R., Perrin, C., Moine, N. Le, & Andréassian, V. (2012). A 
% review of efficiency criteria suitable for evaluating low-flow 
% simulations. Journal of Hydrology, 420–421, 171–182. 
% https://doi.org/10.1016/j.jhydrol.2011.11.055

%% check inputs and set defaults
if nargin < 2
    error('Not enugh input arguments')
elseif nargin > 4
    error('Too many inputs.')    
end

% make sure inputs are vertical and have the same size
obs = obs(:);
sim = sim(:);
if ~size(obs) == size(sim)
    error('Time series not of equal size.')
end

% defaults
w_default = [1,1,1];          % weights
idx_exists = find(obs >= 0);  % time steps to use in calculating of value
% -999 is opten used to denote missing values in observed data. Therefore
% we check for all negative values, and ignore those. 

% update default indices if needed
if nargin < 3 || isempty(idx)
    idx = idx_exists;
else 
    idx = idx(:);
    if islogical(idx) && all(size(idx) == size(obs))
        idx = intersect(find(idx), idx_exists);
    elseif isnumeric(idx)
        idx = intersect(idx, idx_exists);
    else
        error(['Indices should be either ' ...
                'a logical vector of the same size of Qsim and Qobs, or '...
                'a numeric vector of indices']);
    end                                                      % use all non missing Q if idx is not provided otherwise
end


% update defaults weights if needed  
if nargin < 4 || isempty(w)
    w = w_default;
else
    if ~min(size(w)) == 1 || ~max(size(w)) == 3                            % check weights variable for size
        error('Weights should be a 3x1 or 1x3 vector.')                    % or throw error        
    end                                                         % use dafult weight is w is not provided
end   
%% filter to only selected indices
obs = obs(idx);
sim = sim(idx);                                            

%% invert the time series and add a small constant to avoid issues with 0 flows
% Pushpalatha et al (2012) suggests to set e at 1/100th of the mean of the
% observed flow, which is what we'll follow here. The constant is added
% before transforming flows.

% Find the constant
e = mean(obs)/100;

% Apply the constant and transform flows
obs = 1./(obs+e);
sim = 1./(sim+e);

%% calculate components
c(1) = corr(obs,sim);                                             % r: linear correlation
c(2) = std(sim)/std(obs);                                         % alpha: ratio of standard deviations
c(3) = mean(sim)/mean(obs);                                       % beta: bias 

%% calculate value
val = 1-sqrt((w(1)*(c(1)-1))^2 + (w(2)*(c(2)-1))^2 + (w(3)*(c(3)-1))^2);    % weighted KGE

end