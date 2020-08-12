clear sequence group;

t=0:2:500; %time in seconds with tr interval
%s=(t>3 & t<3+5)

for i=1:length(onsets)
        s=(t>onsets{i} & t<(onsets{i} + durations{i}));
        [~,g]=max([s;ones(1,length(t))]);
        g(g>length(onsets{i}))=0;
        group(i,:)=g;
end

[group,n]=max([group;ones(1,length(t))]);
names=[names,{'other'}];
labels=names(n);

f=fopen('test.csv','w')
for i=1:length(labels)
    fprintf(f,"%s,%d\n",labels{i},group(i));
end
        