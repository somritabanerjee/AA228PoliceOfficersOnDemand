
function getCWeighted(crime_data::Matrix,grid_size) ### GETS CRIME MATRIX
    matrix4=crime_data;
    n,m = size(matrix4)
    C = zeros(grid_size,grid_size,24)
    for i = 1:n
        lat = matrix4[i,3]
        long = matrix4[i,4]
        hour = matrix4[i,1]+1
        C[lat,long,hour] += matrix4[i,5]
    end
    total_hourly_crime = zeros(24)
    for h = 1:24
        total_hourly_crime[h] = sum(C[:,:,h])
    end
    for latitude = 1:grid_size
        for longitude = 1:grid_size
            for h = 1:24
                if C[latitude,longitude,h] != 0
                    C[latitude,longitude,h] = C[latitude,longitude,h]/total_hourly_crime[h]
                end
            end
        end
    end
    return C
end
