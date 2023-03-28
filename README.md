```math
\Huge
\underline{\textbf{EC331: Research in Applied Economics}}
```

# Old Dogs and New Tricks: Log Return Density Forecasting Using a Novel Neural Network Architecture and ARMA-GARCH Models

This repo is for my final year undergraduate dissertation in economics at the University of Warwick.

My dissertation compares ARMA-GARCH models of order $(p,p)-(p,p)$, for $p=1,2,3,4,5$, with a few variants of a neural network model that I have developed. The comparison of the two model classes follows a similar methodology to Borup et al. (2022), and uses their multivariate Giacomini-White of equal conditional predictive accuracy to construct a model confidence set (Hansen et al., 2011). A high level overview of the methodology is given in the diagram below. I focus on one step ahead forecasts and use a rolling window technique with no re-estimation at each step to keep the models computationally tractable. I compare the neural network and ARMA-GARCH models on three log return series for some globally large stock indices: the Nikkei 225, the DAX, and the NASDAQ composite.

Suppose we have a set of models $(\mathscr{M}_ i)_ {i=1}^k$, their parametrisations $(\theta_i)_ {i=1}^k$, the assumed distributions of log returns for each model $(f_i)_ {i=1}^k$, training data $(X_i)_ {i=1}^m$ and validation data $(Y_j)_ {j=1}^n$. Then my methodology is as follows:

![image](https://user-images.githubusercontent.com/102311691/228230332-c0a4a405-74a0-4e78-beee-1b52ebf93868.png)


## The Neural Network Model

To forecast densities using a neural network model, I have opted for a semi-parametric approach. First, I assume some parametric, absolutely continuous, distribution of the dependent variable. This can be made to accommodate broader data generating processes by assuming a parametric family of distributions rather than a particular distribution, and increasing the width of the neural network to arbitrary size. My neural network model is based on a series of Long Short-Term Memory and dropout layers, with a final dense layer outputting the parameters of the assumed distribution of the series. Initial attempts to output all parameters with a single LSTM-dropout-dense channel resulted in unusable forecasts, so separate LSTM-dropout-dense channels are used for each parameter of the distribution. The neural network model can be visualed as:

![image](https://user-images.githubusercontent.com/102311691/228261559-ffa659aa-cef9-47f9-93a1-07ca90f66b31.png)


The model is trained using the Adam optimizer, with a custom learning rate schedule, a batch size of 64, and a window size of 10. To calculate gradients, backpropagation through time is used. Stochastic gradient descent is performed on the empricial risk of the model at each batch. The empirical risk can be defined as follows. Suppose we have initialised the neural network with some bias and weight terms. This initialised neural network generates a previsible sequence of forecasts $(V_ n)_ {n\geq 0}$. Given a sequence of input windows, $(\mathbf{X}_ i)_ {i=1}^n$, with associated target values, $(Y_i )_ {i=1}^n$, the empirical risk under a loss function $L$ is given by 

$$L((V_ i , X_ i)_ {i=1}^n, (Y_ i)_ {i=1}^n) = -\sum_ {i=1}^n S(V_ i(X_i) , Y_ i)$$

Where $S$ is some score function rating the accuracy of the forecasts (see section 4.2 of dissertation for details)



