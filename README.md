[![Language](https://img.shields.io/badge/language-Python_3-54a4ff.svg?style=flat-square)](https://www.python.org)
[![License](https://img.shields.io/github/license/patohdzs/project-tinder?style=flat-square)](https://opensource.org/licenses/MIT)

```math
\Huge
\underline{\textbf{EC331: Research in Applied Economics}}
```

# Old Dogs and New Tricks: Log Return Density Forecasting Using a Novel Neural Network Architecture and ARMA-GARCH Models

This repo is for my final year undergraduate dissertation in economics at the University of Warwick. Code for the multivariate Giacomini and White (2006) and model confidence set (Hansen et al., 2011) was adapted from [this github repo](https://github.com/ogrnz/feval).

$\Huge \textbf{Abstract}$ 
> Uncertainty is fundamental in economics. Imperfect or asymmetric information can lead to marked misallocations of resources, and their ubiquity is a hard truth in many economies. Whilst in the past econometricians focused on point and interval forecasts, developments in quantitative finance and risk management have created demand for quick and accurate forecasts of the whole probability distribution. However, accuracy and speed can be conflicting goals, particularly when non-linearities in the data mean complex models are required to accurately predict the probability density function. In this paper, a novel semi-parametric neural network model is developed and compared to a variety of ARMA-GARCH models on the log returns of the NASDAQ composite, Nikkei 225, and DAX stock indices. Using a multivariate version of the Giacomini-White test of equal predictive accuracy \citep{GiacominiWhite,BorupMGW}, a large initial model set of neural network and ARMA-GARCH models is synthesised down to a model confidence set \citep{MCS}. Results indicate that the ARMA-GARCH models outperform the neural network models across all three series, and this result is robust to variations in the testing specification and choice of scoring rule.

My dissertation compares ARMA-GARCH models of order $(p,p)-(p,p)$, for $p=1,2,3,4,5$, with a few variants of a neural network model that I have developed. The comparison of the two model classes follows a similar methodology to Borup et al. (2022), and uses their multivariate Giacomini-White of equal conditional predictive accuracy to construct a model confidence set (Hansen et al., 2011). A high level overview of the methodology is given in the diagram below. I focus on one step ahead forecasts and use a rolling window technique with no re-estimation at each step to keep the models computationally tractable. I compare the neural network and ARMA-GARCH models on three log return series for some globally large stock indices: the Nikkei 225, the DAX, and the NASDAQ composite.

Suppose we have a set of models $(\mathscr{M}_ i)_ {i=1}^k$, their parametrisations $(\theta_i)_ {i=1}^k$, the assumed distributions of log returns for each model $(f_i)_ {i=1}^k$, training data $(X_i)_ {i=1}^m$ and validation data $(Y_j)_ {j=1}^n$. Then my methodology is as follows:

![image](https://user-images.githubusercontent.com/102311691/228230332-c0a4a405-74a0-4e78-beee-1b52ebf93868.png)


## The Neural Network Model

To forecast densities using a neural network model, I have opted for a semi-parametric approach. First, I assume some parametric, absolutely continuous, distribution of the dependent variable. This can be made to accommodate broader data generating processes by assuming a parametric family of distributions rather than a particular distribution, and increasing the width of the neural network to arbitrary size. My neural network model is based on a series of Long Short-Term Memory and dropout layers, with a final dense layer outputting the parameters of the assumed distribution of the series. Initial attempts to output all parameters with a single LSTM-dropout-dense channel resulted in unusable forecasts, so separate LSTM-dropout-dense channels are used for each parameter of the distribution. The neural network model can be visualed as:

![image](https://user-images.githubusercontent.com/102311691/228261559-ffa659aa-cef9-47f9-93a1-07ca90f66b31.png)


The model is trained using the Adam optimizer, with a custom learning rate schedule, a batch size of 64, and a window size of 10. To calculate gradients, backpropagation through time is used. Stochastic gradient descent is performed on the empricial risk of the model at each batch. The empirical risk can be defined as follows. Suppose we have initialised the neural network with some bias and weight terms. This initialised neural network generates a previsible sequence of forecasts $(V_ n)_ {n\geq 0}$. Given a sequence of input windows, $(\mathbf{X}_ i)_ {i=1}^n$, with associated target values, $(Y_i )_ {i=1}^n$, the empirical risk under a loss function $L$ is given by 

$$L((V_ i , X_ i)_ {i=1}^n, (Y_ i)_ {i=1}^n) = -\sum_ {i=1}^n S(V_ i(X_i) , Y_ i)$$

Where $S$ is some score function rating the accuracy of the forecasts (see section 4.2 of dissertation for details)

## The MCS and Multivariate Giacomini-White Test (Hansen et al., 2011 ; Giacomini and White, 2006 ; Borup et al. 2022)

The MCS procedure of Hasen, Lunde, and Nason (2011) is a method of obtaining the set of models from an initial model set, $\mathscr{M}^0$, which are optimal at the $\alpha$\% level. The procedure is iterative, and works by applying some test of equal predictive performance, $\delta_ {\mathscr{M}}$, and some elimination rule, $e_  {\mathscr{M}}$ which is used to remove a model from the set if $\delta_ {\mathscr{M}}$ is rejected. Thus, the procedure results in a sequence of model sets, $\mathscr{M}^0 \supset \mathscr{M}^1 \supset \dots \supset \mathscr{M}^n$, where $\mathscr{M}^n$ contains the optimal model set from $\mathscr{M}^0$ at the $\alpha $\% level.

For $\delta_ {\mathscr{M}}$, I use the multivariate of the Giacomin-White test $\mathscr{M}$ (Giacomini and White, 2006) which was developed by Borup et al. (2022). The test can either be unconditional, thus testing average historical performance, or condtional, thus testing for equal predictive accuracy for forecasts at any given time step. To represent conditioning, some vector of measurable functions, $h_ t$, is used. I chose to select $h_t = (1,\Delta L_t )'$ as the primary test function as this captured a large part of the variation in loss differentials over the validation set. For robustness, I also calculate the MCS using $h_t = (1, y_t,\Delta L_t, \Delta L_{t-1})'$. For more details, see section 4.3 of the dissertation.

# References

- Borup, Daniel and Eriksen, Jonas Nygaard and Kjær, Mads Markvart and Thyrsgaard, Martin,
  [Predicting Bond Return Predictability](http://dx.doi.org/10.2139/ssrn.3513340).
- Giacomini, R. and White, H. (2006). [Tests of conditional predictive ability](https://www.jstor.org/stable/4123083). Econometrica,
74(6):1545–1578.
- Hansen, P. R., Lunde, A., and Nason, J. M. (2011). [The model confidence set](https://www.jstor.org/stable/41057463). Econometrica, 79(2):453–497.



