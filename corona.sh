#!/bin/bash
POSIXLY_CORRECT=yes
#----------------------------------------------Variables-------------------------------------------------
# file
files=()
err_lines=
lines=
# flags
COMMAND=
# filters
FILTERS=()
#histogram
is_histogram=
histogram_length=0
# regex validation
readonly re_id=^[a-zA-Z0-9-]+$
readonly re_date=^[0-9]{4}-[01][0-9]-[0-3][0-9]$
readonly re_file=\.[a-zA-Z]+
readonly months_day_count=(31 29 31 30 31 30 31 31 30 31 30 31)
readonly max_month=12
readonly max_year=9999
readonly s_gender=100000
readonly s_age=10000
readonly s_daily=500
readonly s_monthly=10000
readonly s_yearly=100000
readonly s_countries=100
readonly s_districts=1000
readonly s_regions=10000
# info
readonly info="
\nFILTERS:\n
-a [YYYY-MM-DD] -     consider only people who got infected after a given date\n
-b [YYYY-MM-DD] -     consider only people who got infected before a given date\n
-g [M/Z] -            consider only people with a given gender\n
-s [NUMBER] -         prints as a histogram\n
\nCOMMANDS:\n
infected -    prints out a number of infected people\n
gender -      prints out a number of infected people by gender\n
age -         prints out a number of infected people by age\n
daily -       prints out a number of infected people per day\n
monthly -     prints out a number of infected people per month\n
yearly -      prints out a number of infected people per year\n
countries -   prints out a number of infected people per country\n
districts -   prints out a number of infected people per distinct\n
regions -     prints out a number of infected people per region\n
"
readonly head="id,datum,vek,pohlavi,kraj_nuts_kod,okres_lau_kod,nakaza_v_zahranici,nakaza_zeme_csu_kod,reportovano_khs"
#------------------------------------------Input & Output functions------------------------------------------
# error handler
create_error(){
    echo $1 >&2
    exit 1
}
# input handler
input(){
    awk -v head="$head" '
    BEGIN{is_head=0}
    {gsub(" ","",$0)}
    $0 !~ head {print}
    $0 ~ head && is_head==0 {is_head=1}
    '
}

# output handler (for "key": "value")
output(){
    has_none=$1
    awk -v has_none="$has_none" '
        BEGIN {None=0} 
        {if(length($2)==0&&has_none=="-n"){
            None=$1
        }else{
            if(length($2)!=0){
                print $2":",$1
            }
        }}
        END{if(None!=0){print "None:",None}}'
    
}
# date validation for flags (-a -b)
is_date_valid(){
    date=$1
    if [[ "$date" =~ 20[0-9]{2}-[01][0-9]-[0-3][0-9] ]];then
        return $(echo $date | awk -F- -v max_month="$max_month" -v max_year="$max_year" -v months_str="${months_day_count[*]}" '
        BEGIN { split(months_str,months," ") }
        {print ($1>max_year||$1<0||$2>max_month||$3>months[int($2)]||$2<0||$3<0?0:1)}')
    else
        create_error "Invalid argument. Should be YYYY-MM-DD"
    fi
}
#---------------------------------------------Input--------------------------------------------------
# flags handler
while getopts a:b:g:s:h flag
do
    case $flag in
    h) 
        echo -e $info
        exit 0;;
    a)  if [[ -n $OPTARG ]];then
            FILTERS+=("$flag:$OPTARG")
        fi
        ;;
    b) if [[ -n $OPTARG ]];then
            FILTERS+=("$flag:$OPTARG")
        fi;;
    g) if [[ -n $OPTARG ]];then
            FILTERS+=("$flag:$OPTARG")
        fi;;
    s) 
        is_histogram=1
        if [[ "$OPTARG" =~ ^[0-9]+$ ]];then
            histogram_length=$OPTARG
        else
            COMMAND=$OPTARG
        fi
        ;;
    esac
done

# flag argument's validation
for filter in ${FILTERS[@]}
do
    argument=$(echo $filter | awk -F: '{print $2}')
    if [[ "$filter" =~ ^a ]];then
    is_date_valid $argument
    if [[ $? == "0" ]];then
        create_error "Invalid argument. Should be YYYY-MM-DD"
    fi
    elif [[ "$filter" =~ ^b ]];then
    is_date_valid $argument
    if [[ $? == "0" ]];then
        create_error "Invalid argument. Should be YYYY-MM-DD"
    fi
    elif [[ "$filter" =~ ^g ]];then
    if [[ ! $argument =~ ^[MZ]$ ]];then
        create_error "Invalid argument. Should be M or Z"
    fi
fi
done

shift $(($OPTIND-1))

readonly args=($@)
# reads command
if [[ -z "$COMMAND" ]];then
    COMMAND=${args[0]}
fi

# file input
if [ ! -p /dev/stdin ];then
    for file in ${args[*]};do
        if [[ "$file" =~ \.(csv|csv.gz|csv.bz2)$ ]];then
            files+=($file)         
        fi
    done
    
    if [[ "$COMMAND" == "merge" && ${#files} -gt 0 ]];then
        for file in ${files[*]};do
            if [[ "$file" =~ \.csv$ ]];then
                lines+=$(cat $file | input )
            elif [[ "$file" =~ \.csv\.gz$ ]];then
                lines+=$(zcat $file | input )
            elif [[ "$file" =~ \.csv\.bz2$ ]];then
                lines+=$(bzcat $file | input )
            fi
        done
    else 
        if [[ ${#files} -gt 0 ]];then
            file=${files[0]}
        else    
            echo "Please provide a file (.csv , .csv.gz or .csv.bz2)"
            read file
            if [[ ! "$file" =~ \.csv$ ]];then
                create_error "Invalid name of the file"
            fi
        fi

        if [[ "$file" =~ \.csv$ ]];then
            lines=$(cat $file | input )
        elif [[ "$file" =~ \.csv\.gz$ ]];then
            lines=$(zcat $file | input )
        elif [[ "$file" =~ \.csv\.bz2$ ]];then
            lines=$(bzcat $file | input )
        fi
    fi
else
    lines=$(input)
fi

# if there is no command
if [[ "$file" == "$COMMAND" ]];then
COMMAND=
fi

#---------------------------------------------Functions--------------------------------------------------
# finds max value in "key": "value" line
find_max(){
    awk -F: 'BEGIN {max=0}; ($2>max){max=$2} END {print max}'
}
# validates lines
get_line() {
    echo -e "$lines" | awk -F, -v isError="$1" -v head="$head" -v valid_date="$re_date" -v valid_id="$re_id" -v months_str="${months_day_count[*]}" '
    BEGIN { 
        split(months_str,months," ") 
    }
    {   

        #date
        y=substr($2,0,4)
        m=substr($2,6,2)
        d=substr($2,9,2)

        #borders
        max_month=12
        max_year=9999
        max_day=31

        is_date_invalid=$2 !~ valid_date || d < 0 || m < 0|| m > max_month || y < 0 || y > max_year || d > months[int(m)]

        is_age_invalid=($3<0|| ($3 !~ "^[0-9]+$"))&&length($3)!=0


        if(isError=="invalid"){
            if(length($2)==0)
            {
                next
            }
            
            if(is_date_invalid){
                print "Invalid date:",$0
            }
            if(is_age_invalid){
                print "Invalid age:",$0
            }
        }else{
            if(!is_age_invalid&&!is_date_invalid&&($1 ~ valid_id)&&($0 != head)){
               print $0
            }
        }
    }'
}
# saves validated lines
get_validated_lines(){
    #save lines [invalid date]
    err_lines=$(get_line invalid)
    #save lines [valid date & age]
    lines=$(get_line)
}

#---------------------------------------------FILTERS--------------------------------------------------

if [[ "${#FILTERS[*]}" -gt 0 || ("$COMMAND" != "merge" && "$COMMAND" != "") ]];then
    get_validated_lines
fi

a_filter() {
    echo -e "$lines" | awk -F, -v valid_date="re_date" -v DATE="$1" '{ if(DATE<=$2||length($2)==0){print $0} }'
}

b_filter() {
    echo -e "$lines" | awk -F, -v valid_date="re_date" -v DATE="$1" '{ if(DATE>=$2||length($2)==0){print} }'
}

g_filter() {
    echo -e "$lines" | awk -F, -v valid_date="re_date" -v GENDER="$1" '{if( $4 == GENDER || length($4) == 0 ) {print} }'
}

s_filter(){
        awk -F: -v max="$1" -v len="$histogram_length" -v def="$2" '
        BEGIN {s="";size=0;k=0}
        {
            if(len>0){
                k=$2/max
                size=int(k*len)
            }else{
                k=$2/def
                size=int(k)
            }
            for(i=0;i<size;i++){
                s=s"#"
            }
            print $1":", s
            s=""
        }'
}   
# applies filter to lines
for filter in ${FILTERS[@]}
do
    argument=$(echo $filter | awk -F: '{print $2}')
    if [[ "$filter" =~ ^a ]];then
        lines=$(a_filter $argument)
    elif [[ "$filter" =~ ^b ]];then
        lines=$(b_filter $argument)
    elif [[ "$filter" =~ ^g ]];then
        lines=$(g_filter $argument)
    fi
done

#---------------------------------------------COMMANDS--------------------------------------------------

infected() {
    echo -e "$lines" | wc -l
}

gender() {
    gender_count(){
        awk -F, '
        BEGIN {M=0;Z=0;N=0}
        ($4 ~ /M/){M++}
        ($4 ~ /Z/){Z++}
        (length($4)==0){N++}
        END {
            print "M:",M"\nZ:",Z
            if(N!=0){
                print "None:",N
            }
        }'
    }

    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | gender_count
        else
            max=$(echo -e "$lines" | gender_count | find_max)
            echo -e "$lines" | gender_count | s_filter $max $s_gender
    fi
}

age() {
    age_count(){
        awk -F, 'BEGIN {
                    ages["0-5"]=0;
                    ages["6-15"]=0;
                    ages["16-25"]=0;
                    ages["26-35"]=0;
                    ages["36-45"]=0;
                    ages["46-55"]=0;
                    ages["56-65"]=0;
                    ages["66-75"]=0;
                    ages["76-85"]=0;
                    ages["86-95"]=0;
                    ages["96-105"]=0;
                    ages[">105"]=0;
                    ages["None"]=0;
                }
                NR>1{
                    if(length($3)==0){
                        ages["None"]++
                    }else if($3>=0&&$3<=5){
                        ages["0-5"]++
                    }else if($3>=6&&$3<=15){
                        ages["6-15"]++
                    }else if($3>=16&&$3<=25){
                        ages["16-25"]++
                    }else if($3>=26&&$3<=35){
                        ages["26-35"]++
                    }else if($3>=36&&$3<=45){
                        ages["36-45"]++
                    }else if($3>=46&&$3<=55){
                        ages["46-55"]++
                    }
                    else if($3>=56&&$3<=65){
                        ages["56-65"]++
                    }
                    else if($3>=66&&$3<=75){
                        ages["66-75"]++
                    }
                    else if($3>=76&&$3<=85){
                        ages["76-85"]++
                    }
                    else if($3>=86&&$3<=95){
                        ages["86-95"]++
                    }
                    else if($3>=96&&$3<=105){
                        ages["96-105"]++
                    }
                    else if($3>105){
                        ages[">105"]++
                    }
                }
                END {
                    print "0-5   :",ages["0-5"]
                    print "6-15  :",ages["6-15"]
                    print "16-25 :",ages["16-25"]
                    print "26-35 :",ages["26-35"]
                    print "36-45 :",ages["36-45"]
                    print "46-55 :",ages["46-55"]
                    print "56-65 :",ages["56-65"]
                    print "66-75 :",ages["66-75"]
                    print "76-85 :",ages["76-85"]
                    print "86-95 :",ages["86-95"]
                    print "96-105:",ages["96-105"]
                    print ">105  :",ages[">105"]
                    if(ages["None"]>0){
                        print "None  :",ages["None"]
                    }
                }
                '
    }

    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | age_count
        else
            max=$(echo -e "$lines" | age_count | find_max)
            echo -e "$lines" | age_count | s_filter $max $s_age
    fi
}


daily() {

    daily_count(){
        awk -F, '{print $2}' | sort -M | uniq -c | output -n
    }

    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | daily_count
        else
            max=$(echo -e "$lines" | daily_count | find_max)
            echo -e "$lines" | daily_count | s_filter $max $s_daily
    fi
    
}

monthly() {
    monthly_count(){
        awk -F, '{print substr($2,0,7)}' | sort -M | uniq -c | output -n
    }
    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | monthly_count
        else
            max=$(echo -e "$lines" | monthly_count | find_max)
            echo -e "$lines" | monthly_count | s_filter $max $s_monthly
    fi
}

yearly() {
    yearly_count(){
        awk -F, '{print substr($2,0,4)}' | sort -M | uniq -c | output -n
    }
    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | yearly_count
        else
            max=$(echo -e "$lines" | yearly_count | find_max)
            echo -e "$lines" | yearly_count | s_filter $max $s_yearly
    fi
}

countries() {
    countries_count(){
        awk -F, '{print $8}' | sort -d | uniq -c | output
    }

    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | countries_count
        else
            max=$(echo -e "$lines" | countries_count | find_max)
            echo -e "$lines" | countries_count | s_filter $max $s_countries
    fi
}

districts() {
    districts_count(){
        awk -F, '{print $6}' | sort -n | uniq -c | output -n
    }
    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | districts_count
        else
            max=$(echo -e "$lines" | districts_count | find_max)
            echo -e "$lines" | districts_count | s_filter $max $s_districts
    fi
}

regions() {
    regions_count(){
        awk -F, '{print $5}' | sort -n | uniq -c | output -n
    }
    if [[ -z "$is_histogram" ]];then
            echo -e "$lines" | regions_count
        else
            max=$(echo -e "$lines" | regions_count | find_max)
            echo -e "$lines" | regions_count | s_filter $max $s_regions
    fi
}

output_no_validation(){
    echo $head
    for line in ${lines};do
        echo -e $line
    done
}

merge(){
    echo $head
    for line in ${lines};do
        echo -e $line
    done
}
#----------------------------------------Command calls & output---------------------------------------------
# command handler
case $COMMAND in
'infected') infected ;;
'gender') gender ;;
'age')age ;;
'daily') daily;;
'monthly') monthly;;
'yearly') yearly;;
'countries') countries;;
'districts') districts;;
'regions') regions;;
'merge') merge;;
*)  if [[ -z "$COMMAND" ]];then
        echo $head
        for line in $lines;do
            echo -e $line
        done                    
    else
        create_error "Command doesn't exist! Try -h to see avaliable commands"
    fi
esac

# prints invalid lines
if [[ "${#FILTERS}" -gt 0 || "$COMMAND" != "merge" ]];then
    if [ -n "$err_lines" ];then
        echo -e "$err_lines"
    fi
fi

exit 0

#------------------------------------------------------------------------------------------------
