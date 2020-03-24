close all
clear all
clc

p = system(['svn info ', pwd]);
if (p == 1)
    disp('fare il checkout');
end
%system(['svn update ', pwd]);
addpath('dati-province\');
addpath('dati-regioni\');
addpath('dati-andamento-nazionale\');

prompt = 'Selezionare:\n 1 per provincia \n 2 per regione \n 3 Nazionale \n';
a = input(prompt);

if (a == 1)
    dpccovid19 = readtable('dati-province\dpc-covid19-ita-province.csv');
    prompt = 'Selezionare la procinca Siena (SI), Milano (MI)...\n';
    b = input(prompt, 's');
    rows = (dpccovid19.sigla_provincia == string(b)); 
    city = dpccovid19(rows,:);
    cityNames = city.denominazione_provincia;
    
elseif (a == 2)
    dpccovid19 = readtable('dati-regioni\dpc-covid19-ita-regioni.csv');
    prompt = 'Selezionare la Regione: \n';
    b = input(prompt,'s');
    rows = (dpccovid19.denominazione_regione == string(b)); 
    city = dpccovid19(rows,:);
    cityNames = city.denominazione_regione;
    
else
    dpccovid19 = readtable('dati-andamento-nazionale\dpc-covid19-ita-andamento-nazionale.csv');
    rows = (dpccovid19.stato == "ITA"); 
    city = dpccovid19(rows,:);
    cityNames{1,1} = 'Italia';
    
    
end

cityName  = cityNames {1,1};
C = cellstr(city.data);
newStr = split(C," ");
Date= datetime(newStr(:,1));
giornalieri = [0; diff(city.totale_casi)];
totali = city.totale_casi;


tempi = [0 :length(Date)-1];
plot(Date,city.totale_casi)
figure
plot(Date,giornalieri, 'r')
%cftool
close all

%% Fitting
x= tempi';
y= totali;

% Define function that will be used to fit data: % a/(1+ exp(-k*(x-b)))
% (F is a vector of fitting parameters)
f = @(F,x) F(1) ./ (1 +  exp(-F(2).*(x - F(3))));

F_fitted = nlinfit(x,y,f,[0 0 0]);
timeHorizon = 60;
previsione = f(F_fitted,[0:timeHorizon]);
tt = [0:timeHorizon];
d2 = (diff(diff(previsione))>0);
picco = find(d2==0,1);

% Display fitted coefficients
disp(['F = ',num2str(F_fitted)]);

% Plot the data and fit
figure(1)
x_ = x + Date(1);
plot(x_,y,'*')
hold on
plot(x_,f(F_fitted,x),'g');
plot([Date(1) : Date(1)+timeHorizon],previsione, '--r');
%picco
plot((Date(1) +picco),f(F_fitted,picco),'-p','MarkerFaceColor','red', 'MarkerSize',15);
legend('data','fit', 'previsione');
xlabel('Giorni')
ylabel('Casi totali')
title('previsione per '+ string(cityName))

%% confronto andamento 3 giorni
figure
title('Confronto di 3 giorni per '+ string(cityName))
y2 = y(1:end-2);
y1 = y(1:end-1);
plot(x_,y,'*')
hold on

x2= x(1:end-2);
x1= x(1:end-1);
F2_fitted = nlinfit(x2,y2,f,[0 0 0]);
F1_fitted = nlinfit(x1,y1,f,[0 0 0]);

plot(x_(1:end-2),f(F2_fitted,x2),'r');
plot(x_(1:end-1),f(F1_fitted,x1),'g');
plot(x_,f(F_fitted,x),'b');
legend('-2 giorni','ieri', 'oggi');


figure
hold on
title('Trend Previsioni per '+ string(cityName))
previsione2 = f(F2_fitted,[0:timeHorizon]);
previsione1 = f(F1_fitted,[0:timeHorizon]);
previsione = f(F_fitted,[0:timeHorizon]);

plot([Date(1) : Date(1)+timeHorizon],previsione2, '--r');
plot([Date(1) : Date(1)+timeHorizon],previsione1, '--g');
plot([Date(1) : Date(1)+timeHorizon],previsione, '--b');

legend('-2 giorni','ieri', 'oggi');

%% incremento giornaliero

figure
%f = @(F,x) F(1) ./ (1 +  exp(-F(2).*(x - F(3))));
%f(x) =  F(1).*exp(-((x-F(2))./F(3)).^2)

fg = @(F,x) F(1).*exp(-((x-F(2))./F(3)).^2);
Fg_fitted = nlinfit(x,giornalieri,fg,[5805 1.807 1.56]);
fgiorn = fit(x,giornalieri,'gauss1');
fgiorn2 = fit(x,giornalieri,'gauss2');

timeHorizon = 60;

previsione2 = feval(fgiorn,[0: timeHorizon]);
previsione3 = feval(fgiorn2,[0: timeHorizon]);

plot(x_,giornalieri,'*k')
hold on
%plot(x_,[0; diff(f(F_fitted,x))],'g');
plot([Date(1) : Date(1)+timeHorizon],[0 diff(previsione)], 'r');
plot([Date(1) : Date(1)+timeHorizon],previsione2, 'g');
plot([Date(1) : Date(1)+timeHorizon],previsione3, 'b');
plot([Date(1) : Date(1)+timeHorizon],smooth(previsione3,3), '--b');


[picco, i] = max(diff(previsione));
plot((Date(1) +i),picco,'-p','MarkerFaceColor','red', 'MarkerSize',15);
legend('data','derivata logistica.','gauss1', 'gauss2','gauss2 smooth3');
xlabel('Giorni')
ylabel('Casi totali')
title('previsione per '+ string(cityName))