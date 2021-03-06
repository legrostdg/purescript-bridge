{-# LANGUAGE CPP                   #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE TypeSynonymInstances  #-}

module Main where

import           Control.Monad                             (unless)
import qualified Data.Map                                  as Map
import           Data.Monoid                               ((<>))
import           Data.Proxy
import qualified Data.Text                                 as T
import           Language.PureScript.Bridge
import           Language.PureScript.Bridge.TypeParameters
import           Test.Hspec                                (Spec, describe,
                                                            hspec, it)
import           Test.Hspec.Expectations.Pretty

import           TestData



main :: IO ()
main = hspec $ do allTests


allTests :: Spec
allTests =
  describe "buildBridge" $ do
    it "tests with Int" $
      let bst = buildBridge defaultBridge (mkTypeInfo (Proxy :: Proxy Int))
          ti  = TypeInfo { _typePackage    = "purescript-prim"
                       , _typeModule     = "Prim"
                       , _typeName       = "Int"
                       , _typeParameters = []}
       in bst `shouldBe` ti
    it "tests with custom type Foo" $
      let bst = bridgeSumType (buildBridge defaultBridge) (mkSumType (Proxy :: Proxy Foo))
          st = SumType
                TypeInfo { _typePackage = "" , _typeModule = "TestData" , _typeName = "Foo" , _typeParameters = [] }
                [ DataConstructor { _sigConstructor = "Foo" , _sigValues = Left [] }
                , DataConstructor
                  { _sigConstructor = "Bar"
                  , _sigValues = Left [ TypeInfo { _typePackage = "purescript-prim" , _typeModule = "Prim" , _typeName = "Int" , _typeParameters = [] } ]
                  }
                , DataConstructor
                  { _sigConstructor = "FooBar"
                  , _sigValues = Left [ TypeInfo { _typePackage = "purescript-prim" , _typeModule = "Prim" , _typeName = "Int" , _typeParameters = [] }
                                      , TypeInfo { _typePackage = "purescript-prim" , _typeModule = "Prim" , _typeName = "String" , _typeParameters = [] }
                                      ]
                  }
                ]
       in bst `shouldBe` st
    it "tests the generation of a whole (dummy) module" $
      let advanced = bridgeSumType (buildBridge defaultBridge) (mkSumType (Proxy :: Proxy (Bar A B M1 C)))
          modules = sumTypeToModule advanced Map.empty
          m = head . map moduleToText . Map.elems $ modules
          txt = T.unlines [ "-- File auto generated by purescript-bridge! --"
                          , "module TestData where"
                          , ""
                          , "import Data.Either (Either)"
                          , "import Data.Lens (LensP, PrismP, lens, prism')"
                          , "import Data.Maybe (Maybe, Maybe(..))"
                          , ""
                          , "import Prelude"
                          , "import Data.Generic (class Generic)"
                          , ""
                          , "data Bar a b m c ="
                          , "    Bar1 (Maybe a)"
                          , "  | Bar2 (Either a b)"
                          , "  | Bar3 a"
                          , "  | Bar4 {"
                          , "      myMonadicResult :: m b"
                          , "    }"
                          , ""
                          , "derive instance genericBar :: (Generic a, Generic b, Generic (m b)) => Generic (Bar a b m c)"
                          , ""
                          , "--------------------------------------------------------------------------------"
                          , "_Bar1 :: forall a b m c. PrismP (Bar a b m c) (Maybe a)"
                          , "_Bar1 = prism' Bar1 f"
                          , "  where"
                          , "    f (Bar1 a) = Just $ a"
                          , "    f _ = Nothing"
                          , ""
                          , "_Bar2 :: forall a b m c. PrismP (Bar a b m c) (Either a b)"
                          , "_Bar2 = prism' Bar2 f"
                          , "  where"
                          , "    f (Bar2 a) = Just $ a"
                          , "    f _ = Nothing"
                          , ""
                          , "_Bar3 :: forall a b m c. PrismP (Bar a b m c) a"
                          , "_Bar3 = prism' Bar3 f"
                          , "  where"
                          , "    f (Bar3 a) = Just $ a"
                          , "    f _ = Nothing"
                          , ""
                          , "_Bar4 :: forall a b m c. PrismP (Bar a b m c) { myMonadicResult :: m b}"
                          , "_Bar4 = prism' Bar4 f"
                          , "  where"
                          , "    f (Bar4 r) = Just r"
                          , "    f _ = Nothing"
                          , ""
                          , "--------------------------------------------------------------------------------"
                          ]
      in m `shouldBe` txt
    it "test generation of Prisms" $
      let bar = bridgeSumType (buildBridge defaultBridge) (mkSumType (Proxy :: Proxy (Bar A B M1 C)))
          foo = bridgeSumType (buildBridge defaultBridge) (mkSumType (Proxy :: Proxy Foo))
          barPrisms = sumTypeToPrisms bar
          fooPrisms = sumTypeToPrisms foo
          txt = T.unlines [
                            "_Bar1 :: forall a b m c. PrismP (Bar a b m c) (Maybe a)"
                          , "_Bar1 = prism' Bar1 f"
                          , "  where"
                          , "    f (Bar1 a) = Just $ a"
                          , "    f _ = Nothing"
                          , ""
                          , "_Bar2 :: forall a b m c. PrismP (Bar a b m c) (Either a b)"
                          , "_Bar2 = prism' Bar2 f"
                          , "  where"
                          , "    f (Bar2 a) = Just $ a"
                          , "    f _ = Nothing"
                          , ""
                          , "_Bar3 :: forall a b m c. PrismP (Bar a b m c) a"
                          , "_Bar3 = prism' Bar3 f"
                          , "  where"
                          , "    f (Bar3 a) = Just $ a"
                          , "    f _ = Nothing"
                          , ""
                          , "_Bar4 :: forall a b m c. PrismP (Bar a b m c) { myMonadicResult :: m b}"
                          , "_Bar4 = prism' Bar4 f"
                          , "  where"
                          , "    f (Bar4 r) = Just r"
                          , "    f _ = Nothing"
                          , ""
                          , "_Foo :: PrismP Foo Unit"
                          , "_Foo = prism' (\\_ -> Foo) f"
                          , "  where"
                          , "    f Foo = Just unit"
                          , "    f _ = Nothing"
                          , ""
                          , "_Bar :: PrismP Foo Int"
                          , "_Bar = prism' Bar f"
                          , "  where"
                          , "    f (Bar a) = Just $ a"
                          , "    f _ = Nothing"
                          , ""
                          , "_FooBar :: PrismP Foo { a :: Int, b :: String }"
                          , "_FooBar = prism' (\\{ a, b } -> FooBar a b) f"
                          , "  where"
                          , "    f (FooBar a b) = Just $ { a: a, b: b }"
                          , "    f _ = Nothing"
                          , ""
                          ]
      in (barPrisms <> fooPrisms) `shouldBe` txt
    it "tests generation of lenses" $
      let recType = bridgeSumType (buildBridge defaultBridge) (mkSumType (Proxy :: Proxy (SingleRecord A B)))
          bar = bridgeSumType (buildBridge defaultBridge) (mkSumType (Proxy :: Proxy (Bar A B M1 C)))
          barLenses = sumTypeToLenses bar
          recTypeLenses = sumTypeToLenses recType
          txt = T.unlines [
                            "a :: forall a b. LensP (SingleRecord a b) a"
                          , "a = lens get set"
                          , "  where"
                          , "    get (SingleRecord r) = r._a"
                          , "    set (SingleRecord r) = SingleRecord <<< r { _a = _ }"
                          , ""
                          , "b :: forall a b. LensP (SingleRecord a b) b"
                          , "b = lens get set"
                          , "  where"
                          , "    get (SingleRecord r) = r._b"
                          , "    set (SingleRecord r) = SingleRecord <<< r { _b = _ }"
                          , ""
                          ]
      in (barLenses <> recTypeLenses) `shouldBe` txt

