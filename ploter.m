function deadNum=ploter(Sensors,Model,Sender,TotalCH)
  
    deadNum=0;
    n=Model.n;
    for i=1:n
        %check dead node
        if (Sensors(i).E>0)
            
            if(Sensors(i).type=='N' )      
                plot(Sensors(i).xd,Sensors(i).yd,'o'); 
                text(Sensors(i).xd,Sensors(i).yd,int2str(i),'FontSize',10);
            else %Sensors.type=='C'       
                plot(Sensors(i).xd,Sensors(i).yd,'kx','MarkerSize',10);
                text(Sensors(i).xd,Sensors(i).yd,int2str(i),'FontSize',10);
            end
            
        else
            deadNum=deadNum+1;
            plot(Sensors(i).xd,Sensors(i).yd,'red .');
            text(Sensors(i).xd,Sensors(i).yd,int2str(i),'FontSize',10);
        end
        
        hold on;
        
    end 
%     r=randi([1,n],1,1);
%         plot(Sensors(r+1).xd,Sensors(r+1).yd,'g*','MarkerSize',15); 
%     axis square
%     plot(Sensors(n+1).xd,Sensors(n+1).yd,'g*','MarkerSize',15); 
plot(Sensors(Sender).xd,Sensors(Sender).yd,'g*','MarkerSize',15); 
    axis square
    if ~isempty(TotalCH)
    for i=1:length(TotalCH)
            
%         Receiver=n+1;               %Sink
        Send=TotalCH(i).id;       %CH 
%         Sensors=SendReceivePackets(Sensors,Model,Sender,'Data',Receiver);
         XL1=[Sensors(Send).xd ,Sensors(Sender).xd];
            YL1=[Sensors(Send).yd ,Sensors(Sender).yd];
            plot(XL1,YL1,'k')   
    end
    end
    

end