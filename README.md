```math
\Huge
\underline{\textbf{EC331: Research in Applied Economics}}
```

# Old Dogs and New Tricks: Log Return Density Forecasting Using a Novel Neural Network Architecture and ARMA-GARCH Models

This repo is for my final year undergraduate dissertation in economics at the University of Warwick.


My dissertation compares ARMA-GARCH models of order $(p,p)-(p,p)$, for $p=1,2,3,4,5$, with a few variants of a neural network model that I have developed. The comparison of the two model classes follows a similar methodology to Borup et al. (2022), and uses their multivariate Giacomini-White of equal conditional predictive accuracy to construct a model confidence set (Hansen et al., 2011). A high level overview of the methodology is given in the diagram below. 

Suppose we have a set of models $(\mathscr{M}_i)_ {i=1}^k$, their parametrisations $(\theta_i)_ {i=1}^k$, the assumed distributions of log returns for each model $(f_i)_ {i=1}^k$, training data $(X_i)_ {i=1}^m$ and validation data $(Y_j)_ {j=1}^n$. The my methodology is as follows:

![image](https://user-images.githubusercontent.com/102311691/228230332-c0a4a405-74a0-4e78-beee-1b52ebf93868.png)


## The Neural Network Model





