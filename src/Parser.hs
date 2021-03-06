{-# LANGUAGE DeriveGeneric,  OverloadedStrings #-}

module Parser where

import Data.Maybe (fromJust)
import Data.Aeson
import GHC.Generics
import Data.Typeable
import Data.List
import qualified Data.Text as T
import qualified Data.Vector as V
import qualified Data.HashMap.Lazy as Map
import GHC.Exts    -- (fromList)
import Utility (unwrap, unwrapInt, showFullPrecision, decInd, varName)
import Types (Color, Bg, Breakpoint)

processColorData :: [(T.Text, Value)] -> [Color]
processColorData x =  map (\v -> (fst v, unwrap $ snd $ v)) x

parseColors :: Object -> [Color]
parseColors = processColorData . toList

generateBgRule :: Bg -> T.Text
generateBgRule (name, _) = ".bg-" <> name <> " {\n" <> decInd <> "background-color: " <> (varName name) <> ";\n}"

generateBgRules :: [Bg] -> T.Text
generateBgRules xs = foldl (\acc x -> case acc of
    "" -> acc <> (generateBgRule x)
    _ -> acc <> "\n\n" <> (generateBgRule x)
    ) 
    ""
    xs

buildBreakpoint :: (T.Text, Value) -> [(T.Text, Value)] -> Maybe Breakpoint
buildBreakpoint (a, b) xs = 
    let bp = unwrapInt b
        maxIdx = length xs - 1
        idx = fromJust $ elemIndex (a, b) xs
        isLast = idx == maxIdx
    in if isLast then Just (a, bp, Nothing)
    else Just (a, bp, Just (unwrapInt $ snd $ xs !! (idx + 1) )) 


parseBreakpoints :: [Object] -> [Maybe Breakpoint]
parseBreakpoints xs =  
    let bps = concat $ map toList xs 
    in Nothing:(map (\bp -> buildBreakpoint bp bps) bps)

data Config = Config {
    opacity :: [Float],
    borderWidths :: [Float],
    colors :: [Color] ,
    breakpoints :: [Maybe Breakpoint]
} deriving (Show)

instance FromJSON Config where
    parseJSON = withObject "Config" $ \o -> do
        op <- o .: "opacity"
        bw <- o .: "borderWidths"
        cs <- o .: "colors"
        bps <- o .: "breakpoints"
        return $ Config op bw (parseColors cs) (parseBreakpoints bps)

instance ToJSON Config where
  toJSON config = object
    [ "opacity" .= toJSON (opacity config)
    , "borderWidths" .= toJSON (borderWidths config)
    , "colors" .= toJSON (colors config)
    ]