import {BrowserRouter, Routes, Route} from 'react-router-dom'
import Home from './Home'
import Instances from './Instances'
import Health from './Health'
import NotFound from './NotFound'
import Login from './Login'

export default function App(){
  return (
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home/>}/>
          <Route path="/instances" element={<Instances />}/>
          <Route path="/health" element={<Health/>}/>
          <Route path="/not-found" element={<NotFound />}/>
          <Route path="/login" element={<Login/>}/>
        </Routes>
      </BrowserRouter>
  )
}