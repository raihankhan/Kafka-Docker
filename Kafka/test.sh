while IFS='=' read -r key value
do
    echo $key
    echo $value
    eval ${key}=\${value}
done < test.sh


ans=3
a=5
b=4
c=10
ans=$(( ans+a+b+c ))
echo $ans

