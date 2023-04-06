
clc;
clear;
close all;
warning off all;
tic;

%% Create sensor nodes, Set Parameters and Create Energy Model 
%%%%%%%%%%%%%%%%%%%%%%%%% Initial Parameters %%%%%%%%%%%%%%%%%%%%%%%
n=100;                                  %Number of Nodes in the field
[Area,Model]=setParameters(n);     		%Set Parameters Sensors and Network

%%%%%%%%%%%%%%%%%%%%%%%%% configuration Sensors %%%%%%%%%%%%%%%%%%%%
CreateRandomSen(Model,Area);            %Create a random scenario
load Locations                          %Load sensor Location
Sensors=ConfigureSensors(Model,n,X,Y);
Sender=n+1;     %Sink
TotalCH=[];
ploter(Sensors,Model,Sender,TotalCH);                  %Plot sensors
for i=1:n
    text(Sensors(i).xd,Sensors(i).yd,int2str(i),'FontSize',10);
end
plot(Sensors(Sender).xd,Sensors(Sender).yd,'w*','MarkerSize',15);

%%%%%%%%%%%%%%%%%%%%%%%%%% Parameters initialization %%%%%%%%%%%%%%%%
countCHs=0;         %counter for CHs
flag_first_dead=0;  %flag_first_dead
deadNum=0;          %Number of dead nodes

initEnergy=0;       %Initial Energy
for i=1:n
      initEnergy=Sensors(i).E+initEnergy;
end

SRP=zeros(1,Model.rmax);    %number of sent routing packets
RRP=zeros(1,Model.rmax);    %number of receive routing packets
SDP=zeros(1,Model.rmax);    %number of sent data packets 
RDP=zeros(1,Model.rmax);    %number of receive data packets 

Sum_DEAD=zeros(1,Model.rmax);
CLUSTERHS=zeros(1,Model.rmax);
AllSensorEnergy=zeros(1,Model.rmax);

%%%%%%%%%%%%%%%%%%%%%%%%% Start Simulation %%%%%%%%%%%%%%%%%%%%%%%%%
global srp rrp sdp rdp
srp=0;          %counter number of sent routing packets
rrp=0;          %counter number of receive routing packets
sdp=0;          %counter number of sent data packets 
rdp=0;          %counter number of receive data packets 

%Sink broadcast start message to all nodes

Receiver=1:n;   %All nodes
Sensors=SendReceivePackets(Sensors,Model,Sender,'Hello',Receiver);

% All sensor send location information to Sink .
 Sensors=disToSink(Sensors,Model);
% Sender=1:n;     %All nodes
% Receiver=n+1;   %Sink
% Sensors=SendReceivePackets(Sensors,Model,Sender,'Hello',Receiver);

%Save metrics
SRP(1)=srp;
RRP(1)=rrp;  
SDP(1)=sdp;
RDP(1)=rdp;

%% Main loop program
for r=1:1:Model.rmax

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%
    %This section Operate for each epoch   
    member=[];              %Member of each cluster in per period
    countCHs=0;             %Number of CH in per period
    %counter for bit transmitted to Bases Station and Cluster Heads
    srp=0;          %counter number of sent routing packets
    rrp=0;          %counter number of receive routing packets
    sdp=0;          %counter number of sent data packets to sink
    rdp=0;          %counter number of receive data packets by sink
    %initialization per round
    SRP(r+1)=srp;
    RRP(r+1)=rrp;  
    SDP(r+1)=sdp;
    RDP(r+1)=rdp;   
    pause(1)    %pause simulation
    hold off;       %clear figure
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Sensors=resetSensors(Sensors,Model);
    %allow to sensor to become cluster-head. LEACH Algorithm  
    AroundClear=10;
    if(mod(r,AroundClear)==0) 
        for i=1:1:n
            Sensors(i).G=0;
        end
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot sensors %%%%%%%%%%%%%%%%%%%%%%%
    deadNum=ploter(Sensors,Model,Sender,TotalCH);
    plot(Sensors(Sender).xd,Sensors(Sender).yd,'w*','MarkerSize',15);
    %Save r'th period When the first node dies
    if (deadNum>=1)      
        if(flag_first_dead==0)
            first_dead=r;
            flag_first_dead=1;
        end  
    end
    
%%%%%%%%%%%%%%%%%%%%%%% cluster head election %%%%%%%%%%%%%%%%%%%
    %Selection Candidate Cluster Head Based on LEACH Set-up Phase
    [TotalCH,Sensors]=SelectCH(Sensors,Model,r); 
    
    %Broadcasting CHs to All Sensor that are in Radio Rage CH.
    for i=1:length(TotalCH)
        
        Sender=TotalCH(i).id;
        SenderRR=Model.RR;
        Receiver=findReceiver(Sensors,Model,Sender,SenderRR);   
        Sensors=SendReceivePackets(Sensors,Model,Sender,'Hello',Receiver);
            
    end 
    
    %Sensors join to nearest CH 
    Sensors=JoinToNearestCH(Sensors,Model,TotalCH);
    
%%%%%%%%%%%%%%%%%%%%%%% end of cluster head election phase %%%%%%

%%%%%%%%%%%%%%%%%%%%%%% plot network status in end of set-up phase 

    for i=1:n
        
        if (Sensors(i).type=='N' && Sensors(i).dis2ch<Sensors(i).dis2sink && ...
                Sensors(i).E>0)
            tbl(i,1)=Sensors(i).MCH;
            tbl(i,2)=Sensors(i).E;
            tbl(i,3)=Sensors(i).dis2ch;
            tbl(i,4)=Sensors(i).dis2sink;
            %tbl1(i,1)=Sensors(i).MCH;
            %tbl1(i,2)=Sensors(i).E;
            %bl1(i,3)=Sensors(i).dis2sink;
            XL=[Sensors(i).xd ,Sensors(Sensors(i).MCH).xd];
            YL=[Sensors(i).yd ,Sensors(Sensors(i).MCH).yd];
            hold on
            line(XL,YL)
            
            
        end
        
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% steady-state phase %%%%%%%%%%%%%%%%%
    NumPacket=Model.NumPacket;
    for i=1:1:1%NumPacket 
        
        %Plotter     
        deadNum=ploter(Sensors,Model,Sender,TotalCH);
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% All sensor send data packet to  CH 
        for j=1:length(TotalCH)
            
            Receiver=TotalCH(j).id;
            Sender=findSender(Sensors,Model,Receiver); 
            Sensors=SendReceivePackets(Sensors,Model,Sender,'Data',Receiver);
            
        end
        
    end
    
    
%%%%%%%%%%%% send Data packet from CH to Sink after Data aggregation
    for i=1:length(TotalCH)
            
        Receiver=n+1;               %Sink
        Sender=TotalCH(i).id;       %CH 
        Sensors=SendReceivePackets(Sensors,Model,Sender,'Data',Receiver);
            
    end
%%% send data packet directly from other nodes(that aren't in each cluster) to Sink
    for i=1:n
        if(Sensors(i).MCH==Sensors(n+1).id)
            Receiver=n+1;               %Sink
            Sender=Sensors(i).id;       %Other Nodes 
            Sensors=SendReceivePackets(Sensors,Model,Sender,'Data',Receiver);
        end
    end
 
   
%% STATISTICS
     
    Sum_DEAD(r+1)=deadNum;
    
    SRP(r+1)=srp;
    RRP(r+1)=rrp;  
    SDP(r+1)=sdp;
    RDP(r+1)=rdp;
    
    CLUSTERHS(r+1)=countCHs;
    
    alive=0;
    SensorEnergy=0;
    for i=1:n
        if Sensors(i).E>0
            alive=alive+1;
            SensorEnergy=SensorEnergy+Sensors(i).E;
        end
    end
    AliveSensors(r)=alive; %#ok
    
    SumEnergyAllSensor(r+1)=SensorEnergy; %#ok
    
    AvgEnergyAllSensor(r+1)=SensorEnergy/alive; %#ok
    
    ConsumEnergy(r+1)=(initEnergy-SumEnergyAllSensor(r+1))/n; %#ok
    
    En=0;
    for i=1:n
        if Sensors(i).E>0
            En=En+(Sensors(i).E-AvgEnergyAllSensor(r+1))^2;
        end
    end
    
    Enheraf(r+1)=En/alive; %#ok
    
    title(sprintf('Round=%d,Dead nodes=%d', r+1, deadNum)) 
    
   %dead
   if(n==deadNum)
       
       lastPeriod=r;  
       break;
       
   end
  
end % for r=0:1:rmax

disp('End of Simulation');
toc;
disp('Create Report...')

filename=sprintf('leach%d.mat',n);

%% Save Report
save(filename);
figure
plot(1:r,AliveSensors,'g-','MarkerSize',10,'Linewidth',2);
grid on
title('Number of rounds Vs AliveSensors','Fontsize',12);
xlabel('Number of rounds','Fontsize',10);
ylabel('AliveSensors','Fontsize',10);

figure
plot(1:r,AvgEnergyAllSensor(1,1:r),'r-','MarkerSize',10,'Linewidth',2);
grid on
title('Number of rounds Vs AvgEnergyAllSensor','Fontsize',12);
xlabel('Number of rounds','Fontsize',10);
ylabel('AvgEnergyAllSensor','Fontsize',10);

figure
plot(1:r,ConsumEnergy(1,1:r),'c-','MarkerSize',10,'Linewidth',2);
grid on
title('Number of rounds Vs ConsumEnergy','Fontsize',12);
xlabel('Number of rounds','Fontsize',10);
ylabel('ConsumEnergy','Fontsize',10);

figure
plot(1:r,SumEnergyAllSensor(1,1:r),'c-','MarkerSize',10,'Linewidth',2);
grid on
title('Number of rounds Vs SumEnergyAllSensor','Fontsize',12);
xlabel('Number of rounds','Fontsize',10);
ylabel('SumEnergyAllSensor','Fontsize',10);

figure
plot(AvgEnergyAllSensor,ConsumEnergy,'m-','MarkerSize',10,'Linewidth',2);
grid on
title('AvgEnergyAllSensor Vs ConsumEnergy','Fontsize',12);
xlabel('AvgEnergyAllSensor','Fontsize',10);
ylabel('ConsumEnergy','Fontsize',10);

figure
plot(AvgEnergyAllSensor,SumEnergyAllSensor,'m-','MarkerSize',10,'Linewidth',2);
grid on
title('AvgEnergyAllSensor Vs SumEnergyAllSensor','Fontsize',12);
xlabel('AvgEnergyAllSensor','Fontsize',10);
ylabel('SumEnergyAllSensor','Fontsize',10);
