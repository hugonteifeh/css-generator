{-# LANGUAGE DeriveGeneric,  OverloadedStrings #-}

module Border where

import qualified Data.Text as T
import Numeric (showFFloat)
import Types
import Data.List


isInt :: (RealFrac a) => a -> Bool
isInt x = x == fromInteger (round x)

unwrap (Just num) = num

validInt :: Float -> Bool
validInt x = (fromInteger (round x) :: Float) == x

showFullPrecision :: Float -> T.Text
showFullPrecision x = T.pack $ showFFloat Nothing x ""

showInt :: Int -> T.Text
showInt x = T.pack $ show x

showFloat :: Float -> T.Text
showFloat x | validInt x = T.pack $ show $ round x
            | otherwise =  showFullPrecision x

decInd = "  "

varName :: T.Text -> T.Text
varName x = "var(--" <> x <> ")"

genBrClrRule :: Color -> T.Text
genBrClrRule (name, _) = 
  ".b--" <> name
  <> " {\n" <> decInd 
  <> "border-color: " 
  <> (varName name) <> ";\n}"

genBrClrRules :: [Color] -> T.Text
genBrClrRules xs = foldl (\acc x -> case acc of
    "" -> acc <> (genBrClrRule x)
    _ -> acc <> "\n\n" <> (genBrClrRule x)
    ) 
    ""
    xs


elemIndex' x xs = unwrap $ elemIndex x xs 

createBPBlockStart :: Maybe Breakpoint -> T.Text
createBPBlockStart Nothing = "" 
createBPBlockStart (Just (_, b, Just c)) = "@media (min-width: " <> (T.pack $ show b) <> "em) and (max-width: calc(" <> (T.pack $ show c) <> "em - 1px)) {"
createBPBlockStart (Just (_, b, Nothing)) = "@media (min-width: " <> (T.pack $ show b) <> "em) {"

createBPBlockEnd :: Maybe Breakpoint -> T.Text
createBPBlockEnd Nothing = ""
createBPBlockEnd _ = "\n\n}\n\n"

fst' (a, b, c) = a

data Side = TopSide | RightSide | BottomSide | LeftSide

getBPSuffix :: Maybe Breakpoint  -> T.Text
getBPSuffix x = case x of
    Nothing -> ""
    Just (a, _, _) -> "-" <> a

genBWClassName :: Int -> Maybe Breakpoint -> Maybe Side -> T.Text
genBWClassName x y z = case z of
    Nothing -> ".bw" <> (showInt x) <> (getBPSuffix y)
    (Just TopSide) -> ".bt-" <> (showInt x) <> (getBPSuffix y)
    (Just RightSide) -> ".br-" <> (showInt x) <> (getBPSuffix y)
    (Just BottomSide) -> ".bb-" <> (showInt x) <> (getBPSuffix y)
    (Just LeftSide) -> ".bl-" <> (showInt x) <> (getBPSuffix y)

genBWDeclaration :: Float -> Maybe Side -> T.Text
genBWDeclaration x y = case y of
    Nothing ->  "border-width: " <> (showFloat x) <> "rem;\n}"
    (Just TopSide) ->  "border-top-width: " <> (showFloat x) <> "rem;\n}"
    (Just RightSide) ->  "border-right-width: " <> (showFloat x) <> "rem;\n}"
    (Just BottomSide) ->  "border-bottom-width: " <> (showFloat x) <> "rem;\n}"
    (Just LeftSide) ->  "border-left-width: " <> (showFloat x) <> "rem;\n}"

genBWRule :: (Int, Float, Maybe Breakpoint, Maybe Side) -> T.Text
genBWRule (a, b, c, d) =  genBWClassName a c d
              <> " {\n" <> decInd 
              <> (genBWDeclaration b d)


{-
  Breakpint 
    Side 1 rules
     - width1
     - width2
     - width3
     - etc
    Side 2 rules
-}

genBWSideRules :: [Float] -> Maybe Breakpoint -> Maybe Side -> T.Text
genBWSideRules xs bp s = foldl (\acc x -> 
        let l = elemIndex' x xs
        in acc <> "\n\n" <> (genBWRule (l, x, bp, s))
        ) 
        ""
        xs

getBWSidesRules :: [Float] -> Maybe Breakpoint -> T.Text
getBWSidesRules xs bp = 
    let sides = [Nothing, Just TopSide, Just RightSide, Just BottomSide, Just LeftSide]
    in foldl (\acc s -> acc <> "\n" <> (genBWSideRules xs bp s)) 
        ""
        sides

genBWBreakpointCss :: [Float] -> Maybe Breakpoint -> T.Text
genBWBreakpointCss ws bp = 
        let startBlock = createBPBlockStart bp
            endBlock   = createBPBlockEnd bp
        in startBlock 
        <> (getBWSidesRules ws bp)
        <> endBlock

genBWCSS ::  [Float] -> [Maybe Breakpoint] -> T.Text
genBWCSS xs bps = foldl (\acc bp -> acc <> (genBWBreakpointCss xs bp)) "" bps

--genCss :: [Float] -> [Maybe Breakpoint] -> T.Text
--genCss xs bps = foldl (\acc bp -> acc <> "\n\n" <> (genBWCSS xs bp)) "" bps