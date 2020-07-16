#!/bin/bash

compose_tif() {
  local positional_args=()
  local gdalbuildvrt_args=()
  local gdaltranslate_args=()
  local ot="Float32"
  local k_funcargs=""
  local k_st=""

  while [[ $# -ne 0 ]]; do
    case $1 in
      "-te")
        gdalbuildvrt_args+=("$1" "$2" "$3" "$4" "$5")
        shift 5
        ;;
      "-tr")
        gdalbuildvrt_args+=("$1" "$2" "$3")
        shift 3
        ;;
      "-ot")
        ot=$2
        shift 2
        ;;
      "-mo") # Metadata
        gdaltranslate_args+=("$1" "$2")
        shift 2
        ;;
      "-k_funcargs")
        k_funcargs=$2
        shift 2
        ;;
      "-k_st") # Source transfer type
        k_st=$2
        shift 2
        ;;
      *)
        positional_args+=("$1")
        shift 1
        ;;
    esac
  done

  if [[ -z "$k_st" ]]; then
    k_st=$ot
  fi

  local target_tif=${positional_args[0]}
  local python_function=${positional_args[1]}
  local original_files=("${positional_args[@]:2}")

  if [[ -e "$target_tif" ]]; then
    return
  fi

  local vrt_file=${target_tif%.*}.vrt
  gdalbuildvrt_args+=("$vrt_file" "${original_files[@]}")
  gdaltranslate_args+=(-co "COMPRESS=LZW" -co "PREDICTOR=2" "$vrt_file" "$target_tif")

  gdalbuildvrt "${gdalbuildvrt_args[@]}"
  sed -i -E '/<VRTRasterBand/{
    s/<VRTRasterBand/& subClass="VRTDerivedRasterBand"/
    s/(dataType=")([^"]*)(")/\1'"$ot"'\3/
    a <PixelFunctionLanguage>Python</PixelFunctionLanguage>
    a <PixelFunctionType>'"$python_function"'</PixelFunctionType>
    a <PixelFunctionArguments '"$k_funcargs"' />
    a <SourceTransferType>'"$k_st"'</SourceTransferType>
  }' "$vrt_file"
  gdal_translate "${gdaltranslate_args[@]}"
  rm "$vrt_file"
}

