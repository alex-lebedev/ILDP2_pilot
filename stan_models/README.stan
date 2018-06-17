data {
  int<lower=1> T; 
  int<lower=1> N;
  int<lower=1,upper=2> stimulus[N,T];     
  int shock[N,T];  // electric shocks 
  real response[N,T]; 
}

transformed data {
  vector[2] initV;  // initial values for response
  initV = rep_vector(0.0, 2);
}

parameters {
    // Hyper(group)-parameters  
  vector[2] mu_p; // means of Hyperparameters
  vector<lower=0>[2] sigma; // variances of Hyperparameters
  real<lower=0> sigma0; // noise in response
  
  // Subject-lresponseel raw parameters (for Matt trick)
  vector[N] A_pr;    // learning rate
  vector[N] k_pr;  // inverse temperature
}

transformed parameters {
  // subject-lresponseel parameters
  vector<lower=0,upper=1>[N] A;
  vector<lower=0,upper=100>[N] k;

   for (i in 1:N) {
  A[i]   = Phi_approx( mu_p[1]  + sigma[1]  * A_pr[i]);
  k[i]   = Phi_approx( mu_p[2]  + sigma[2]  * k_pr[i])*100; // scale according to upper on line 28
   }
}


model{
  // Hyperparameters:
  mu_p  ~ normal(0, 1); 
  sigma ~ cauchy(0, 5);  
  k_pr ~ normal(0,1);
  A_pr ~ normal(0,1);
  sigma0 ~ cauchy(0,100); // depends on scale of response

for (i in 1:N) {
    vector[2] EV; // expected value
    real PE;      // prediction error
    
    EV = initV;
  for (t in 1:T) {        
    // Response
    response[i,t] ~ gamma( EV[stimulus[i,t]] * k[i],sigma0);
      
    // prediction error 
    PE = shock[i,t] - EV[stimulus[i,t]];
      
    // value updating (learning) 
   EV[stimulus[i,t]] = EV[stimulus[i,t]] + A[i] * PE; 
   }
   }
}