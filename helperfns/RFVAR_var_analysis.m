function [FEVD_array,cov_array,OIRF_array,corr_array] = RFVAR_var_analysis(horizon,pphi,Ssigma_array,model)
% The usual Orthogonalized IRF for a demeaned VAR
% The initial shock size is normalized to be unity
N = model.N;
p = model.p;
M1 = model.M1;
M2 = model.M2;
Pphi_array = reshape(pphi,N,N,p,M1);

%% initialize containers
FEVD_array = zeros(N,N,N,M1,M2);
cov_array = zeros(N,N,M1,M2);
corr_array = zeros(N,N,M1,M2);
OIRF_array = zeros(N,N,horizon+1,M1,M2);
unnormalized_OIRF_array = zeros(N,N,horizon+1,M1,M2);

for m1 = 1:M1
	for m2 = 1:M2
		%% load in the VAR operator, find the inverse
		Pphi_L = LagOp(eye(N));
		for j = 1:p
			Pphi_L.Coefficients{j} = -squeeze(Pphi_array(:,:,j,m1));
		end

		Ssigma_now = Ssigma_array(:,:,m2);
		L = chol(Ssigma_now,'lower');
		Ppsi_L = eye(N)/Pphi_L;

		%% Compute FEVD and total variance
		D = Ppsi_L.Degree;
		tmp_table = zeros(N,N,N);
		for h = 0:D
			for i = 1:N
				Ppsi = Ppsi_L.Coefficients{h};
				tmp_table(:,:,i) = tmp_table(:,:,i) + Ppsi*L(:,i)*L(:,i)'*Ppsi';
			end
		end
		cov_mat = sum(tmp_table,3);
		for i = 1:N
			FEVD_array(:,:,i,m1,m2) = 100*tmp_table(:,:,i)./cov_mat;
		end
		cov_array(:,:,m1,m2) = cov_mat;
		for i = 1:N
			for j = 1:N
				if i == j
					corr_array(i,j,m1,m2) = sqrt(cov_array(i,j,m1,m2));
				else
					corr_array(i,j,m1,m2) = cov_array(i,j,m1,m2)...
						/sqrt(cov_array(i,i,m1,m2)*cov_array(j,j,m1,m2));
				end
			end
		end

		%% Pick up IRF
		for h = 0:horizon
			unnormalized_OIRF_array(:,:,h+1,m1,m2) = Ppsi_L.Coefficients{h}*L;
		end
		for i_shock = 1:N
			OIRF_array(:,i_shock,:,m1,m2) = unnormalized_OIRF_array(:,i_shock,:,m1,m2)...
				/unnormalized_OIRF_array(i_shock,i_shock,1,m1,m2);
		end

	end
end


end
