classdef m_30_mopex2_7p_5s < MARRMoT_model
    % Class for mopex2 model
    properties
        % in case the model has any specific properties (eg derived theta,
        % add it here)
    end
    methods
        
        % this function runs once as soon as the model object is created
        % and sets all the static properties of the model
        function obj = m_30_mopex2_7p_5s(delta_t, theta)
            obj.numStores = 5;                                             % number of model stores
            obj.numFluxes = 10;                                            % number of model fluxes
            obj.numParams = 7;
            
            obj.JacobPattern  = [1,0,0,0,0;
                                 1,1,0,0,0;
                                 0,1,1,0,0;
                                 0,1,0,1,0;
                                 0,0,1,0,1];                               % Jacobian matrix of model store ODEs
                             
            obj.parRanges = [-3  , 3;       % tcrit, Snowfall & snowmelt temperature [oC]
                             0   , 20;      % ddf, Degree-day factor for snowmelt [mm/oC/d]
                             1   , 2000;    % Sb1, Maximum soil moisture storage [mm]
                             0   , 1 ;      % tw, Groundwater leakage time [d-1]
                             0   , 1 ;      % tu, Slow flow routing response time [d-1]
                             1   , 2000;    % se, Root zone storage capacity [mm]
                             0   , 1];      % tc, Mean residence time [d-1]
            
            obj.StoreNames = ["S1" "S2" "S3" "S4" "S5"];                   % Names for the stores
            obj.FluxNames  = ["ps", "pr",  "qn",  "et1", "q1f",...
                              "qw", "et2", "q2u", "qf", "qs"];             % Names for the fluxes
            
            obj.Flux_Ea_idx = [4 7];                                       % Index or indices of fluxes to add to Actual ET
            obj.Flux_Q_idx  = [9 10];                                      % Index or indices of fluxes to add to Streamflow
            
            % setting delta_t and theta triggers the function obj.init()
            if nargin > 0 && ~isempty(delta_t)
                obj.delta_t = delta_t;
            end
            if nargin > 1 && ~isempty(theta)
                obj.theta = theta;
            end
        end
        
        % INIT is run automatically as soon as both theta and delta_t are
        % set (it is therefore ran only once at the beginning of the run. 
        % Use it to initialise all the model parameters (in case there are
        % derived parameters) and unit hydrographs and set minima and
        % maxima for stores based on parameters.
        function obj = init(obj)          
            % min and max of stores
            obj.store_min = zeros(1,obj.numStores);
            obj.store_max = inf(1,obj.numStores);
        end
        
        % MODEL_FUN are the model governing equations in state-space formulation
        function [dS, fluxes] = model_fun(obj, S)
            % parameters
            theta   = obj.theta;
            tcrit = theta(1);     % Snowfall & snowmelt temperature [oC]
            ddf   = theta(2);     % Degree-day factor for snowmelt [mm/oC/d]
            s2max = theta(3);     % Maximum soil moisture storage [mm]
            tw    = theta(4);     % Groundwater leakage time [d-1]
            tu    = theta(5);     % Slow flow routing response time [d-1]
            se    = theta(6);     % Root zone storage capacity [mm]
            tc    = theta(7);     % Mean residence time [d-1]
            
            % delta_t
            delta_t = obj.delta_t;
            
            % stores
            S1 = S(1);
            S2 = S(2);
            S3 = S(3);
            S4 = S(4);
            S5 = S(5);
            
            % climate input
            climate_in = obj.input_climate;
            P  = climate_in(1);
            Ep = climate_in(2);
            T  = climate_in(3);
            
            % fluxes functions
            flux_ps   = snowfall_1(P,T,tcrit);
            flux_pr   = rainfall_1(P,T,tcrit);
            flux_qn   = melt_1(ddf,tcrit,T,S1,delta_t);
            flux_et1  = evap_7(S2,s2max,Ep,delta_t);
            flux_q1f  = saturation_1(flux_pr+flux_qn,S2,s2max);
            flux_qw   = recharge_3(tw,S2);
            flux_et2  = evap_7(S3,se,Ep,delta_t);
            flux_q2u  = baseflow_1(tu,S3);
            flux_qf   = baseflow_1(tc,S4);
            flux_qs   = baseflow_1(tc,S5);

            % stores ODEs
            dS1 = flux_ps - flux_qn;
            dS2 = flux_pr + flux_qn - flux_et1 - flux_q1f - flux_qw;
            dS3 = flux_qw - flux_et2 - flux_q2u;    
            dS4 = flux_q1f - flux_qf;    
            dS5 = flux_q2u - flux_qs; 
            
            
            % outputs
            dS = [dS1 dS2 dS3 dS4 dS5];
            fluxes = [flux_ps, flux_pr,  flux_qn,  flux_et1, flux_q1f,...
                      flux_qw, flux_et2, flux_q2u, flux_qf,  flux_qs];
        end
        
        % STEP runs at the end of every timestep, use it to update
        % still-to-flow vectors from unit hydrographs
        function step(obj, fluxes)
        end
    end
end