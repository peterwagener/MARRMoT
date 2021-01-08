classdef m_44_echo_16p_6s < MARRMoT_model
    % Class for echo model
    properties
        % in case the model has any specific properties (eg derived theta,
        % add it here)
        
        aux_theta         % auxiliary parameters
    end
    methods
        
        % this function runs once as soon as the model object is created
        % and sets all the static properties of the model
        function obj = m_44_echo_16p_6s(delta_t, theta)
            obj.numStores = 6;                                             % number of model stores
            obj.numFluxes = 20;                                            % number of model fluxes
            obj.numParams = 16; 

            obj.JacobPattern  = [1,0,0,0,0,0;
                                 1,1,1,0,0,0;
                                 1,1,1,0,0,0;
                                 1,1,1,1,0,0;
                                 0,0,0,1,1,0;
                                 0,0,0,1,0,1];                             % Jacobian matrix of model store ODEs
                             
            obj.parRanges = [    0, 5;      % rho, Maximum interception storage [mm]
                                -3, 5;      % ts, Threshold temperature for snowfall [oC]
                                -3, 3;      % tm, Threshold temperature for snowmelt [oC]
                                 0, 20;     % as, Degree-day factor [mm/oC/d]
                                 0, 1;      % af, Refreezing reduction factor [-]
                                 0, 2;      % gmax, Maximum melt due to ground-heat flux [mm/d]
                                 0, 1;      % the, Water-holding capacity of snow [-]
                                 0, 200;    % phi, Maximum infiltration rate [mm/d]
                                 1, 2000;   % smax, Maximum soil moisture storage [mm]
                                 0.05, 0.95;% fsm, Plant stress point as a fraction of Smax [-]
                                 0.05, 0.95;% fsw, Wilting point as fraction of sm [-]
                                 0, 1;      % ksat,  Runoff rate from soil moisture [d-1]
                                 0, 5;      % c, Runoff non-linearity from soil moisture [-]
                                 0, 20;     % lmax, Groundwater flux [mm/d]
                                 0, 1;      % kf, Runoff coefficient [d-1]
                                 0, 1];     % ks, Runoff coefficient [d-1]
         
            obj.StoreNames = ["S1" "S2" "S3" "S4" "S5" "S6"];              % Names for the stores
            obj.FluxNames  = ["ei", "pn",  "ps", "pr", "ms"...
                              "fs", "gs",  "mw", "ew", "eq"...
                              "rh", "eps", "et", "fi", "rd"...
                              "l",  "lf",  "ls", "rf", "rs"];              % Names for the fluxes
            
            obj.Flux_Ea_idx = [1 13];                                      % Index or indices of fluxes to add to Actual ET
            obj.Flux_Q_idx  = [11 15 19 20];                               % Index or indices of fluxes to add to Streamflow
            
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
            % parameters
            theta = obj.theta;
            smax = theta(9);     % Maximum soil moisture storage [mm]
            fsm  = theta(10);    % Plant stress point as a fraction of Smax [-]
            fsw  = theta(11);    % Wilting point as fraction of sm [-]
            
            % auxiliary parameters
            sm   = fsm*smax;     % Plant stress point [mm]
            sw   = fsw*sm;       % Wilting point [mm]
            obj.aux_theta = [sm, sw];
            
            % min and max of stores
            obj.store_min = zeros(1,obj.numStores);
            obj.store_max = inf(1,obj.numStores);
        end
        
        % MODEL_FUN are the model governing equations in state-space formulation
        function [dS, fluxes] = model_fun(obj, S)
            % parameters
            theta = obj.theta;
            rho  = theta(1);     % Maximum interception storage [mm]
            ts   = theta(2);     % Threshold temperature for snowfall [oC]
            tm   = theta(3);     % Threshold temperature for snowmelt [oC]
            as   = theta(4);     % Degree-day factor [mm/oC/d]
            af   = theta(5);     % Refreezing reduction factor [-] 
            gmax = theta(6);     % Maximum melt due to ground-heat flux [mm/d]
            the  = theta(7);     % Water-holding capacity of snow [-]
            phi  = theta(8);     % Maximum infiltration rate [mm/d]
            smax = theta(9);     % Maximum soil moisture storage [mm]
            fsm  = theta(10);    % Plant stress point as a fraction of Smax [-]
            fsw  = theta(11);    % Wilting point as fraction of sm [-]
            ksat = theta(12);    % Runoff rate from soil moisture [d-1]
            c    = theta(13);    % Runoff non-linearity from soil moisture [-]
            lmax = theta(14);    % Groundwater flux [mm/d]
            kf   = theta(15);    % Runoff coefficient [d-1]
            ks   = theta(16);    % Runoff coefficient [d-1]
            
            % auxiliary parameters
            aux_theta = obj.aux_theta;
            sm   = aux_theta(1);  % Plant stress point [mm]
            sw   = aux_theta(2);  % Wilting point [mm]
            
            % delta_t
            delta_t = obj.delta_t;
            
            % stores
            S1 = S(1);
            S2 = S(2);
            S3 = S(3);
            S4 = S(4);
            S5 = S(5);
            S6 = S(6);
            
            % climate input
            climate_in = obj.input_climate;
            P  = climate_in(1);
            Ep = climate_in(2);
            T  = climate_in(3);
            
            % fluxes functions
            flux_ei = evap_1(S1,Ep,delta_t);
            flux_pn = interception_1(P,S1,rho);
            flux_ps = snowfall_1(flux_pn,T,ts);
            flux_pr = rainfall_1(flux_pn,T,ts);
            flux_ms = melt_1(as,tm,T,S2,delta_t);
            flux_fs = refreeze_1(af,as,tm,T,S3,delta_t);
            flux_gs = melt_2(gmax,S2,delta_t);
            flux_mw = saturation_1(flux_pr+flux_ms,S3,the*S2);
            flux_ew = excess_1(obj.Sold(3),the*S2,delta_t);
            flux_eq = flux_mw + flux_gs + flux_ew;
            flux_fi = infiltration_4(flux_eq,phi);
            flux_rh = effective_1(flux_eq,flux_fi);
            flux_eps= effective_1(Ep,flux_ei);
            flux_et = evap_22(sw,sm,S4,flux_eps,delta_t);
            flux_rd = saturation_1(flux_fi,S4,smax);
            flux_l  = recharge_6(ksat,c,S4,delta_t);
            flux_ls = recharge_7(lmax,flux_l);
            flux_lf = effective_1(flux_l,flux_ls);
            flux_rf = baseflow_1(kf,S5);
            flux_rs = baseflow_1(ks,S6);

            % stores ODEs
            dS1 = P       - flux_ei - flux_pn;
            dS2 = flux_ps + flux_fs - flux_ms - flux_gs;
            dS3 = flux_pr + flux_ms - flux_fs - flux_mw - flux_ew;
            dS4 = flux_fi - flux_et - flux_rd - flux_l;
            dS5 = flux_lf - flux_rf;
            dS6 = flux_ls - flux_rs;
            
            % outputs
            dS = [dS1 dS2 dS3 dS4 dS5 dS6];
            fluxes = [flux_ei flux_pn  flux_ps flux_pr flux_ms...
                      flux_fs flux_gs  flux_mw flux_ew flux_eq...
                      flux_rh flux_eps flux_et flux_fi flux_rd...
                      flux_l  flux_lf  flux_ls flux_rf flux_rs];
        end
        
        % STEP runs at the end of every timestep, use it to update
        % still-to-flow vectors from unit hydrographs
        function step(obj, fluxes)
        end
    end
end